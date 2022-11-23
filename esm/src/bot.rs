use crate::token::TokenManager;
use crate::*;

use message_io::network::{Endpoint, NetEvent, SendStatus, Transport};
use message_io::node::{self, NodeHandler, NodeListener, NodeTask};
use std::net::ToSocketAddrs;
use std::sync::atomic::AtomicI64;
use std::sync::Mutex as SyncMutex;
use std::time::Duration;
use tokio::sync::mpsc::UnboundedReceiver;

lazy_static! {
    pub static ref TOKEN_MANAGER: Arc<SyncMutex<TokenManager>> =
        Arc::new(SyncMutex::new(TokenManager::new()));
    static ref INIT: Arc<SyncMutex<Init>> = Arc::new(SyncMutex::new(Init::default()));
    static ref PING_RECEIVED: AtomicBool = AtomicBool::new(false);
    static ref CONNECTED: AtomicBool = AtomicBool::new(false);
    static ref ENDPOINT: Arc<SyncMutex<Option<Endpoint>>> = Arc::new(SyncMutex::new(None));
    static ref HANDLER: Arc<SyncMutex<NodeHandler<NetworkSignal>>> = {
        let (handler, _) = node::split();
        Arc::new(SyncMutex::new(handler))
    };
    static ref LISTENER_TASK: Arc<SyncMutex<Option<NodeTask>>> = Arc::new(SyncMutex::new(None));
    static ref RECONNECTION_COUNT: AtomicI64 = AtomicI64::new(0);
}



enum NetworkSignal {
    Init,
}

pub async fn initialize(receiver: UnboundedReceiver<BotRequest>) {
    trace!("[bot::initialize] Loading token");

    if let Err(e) = lock!(TOKEN_MANAGER).load() {
        error!("[bot#initialize] ❌ {}", e);
    };

    let (handler, listener) = node::split::<NetworkSignal>();
    *lock!(HANDLER) = handler;

    routing_thread(receiver).await;
    listener_thread(listener);
}

async fn routing_thread(mut receiver: UnboundedReceiver<BotRequest>) {
    tokio::spawn(async move {
        trace!("[bot::routing_thread] Receiving");
        loop {
            let Some(request) = receiver.recv().await else {
                warn!("[bot::routing_thread] Failed to receive request");
                continue;
            };

            debug!("[bot::routing_thread] Processing request: {request}");
            match request {
                BotRequest::Connect => {
                    tokio::spawn(async {
                        trace!("[bot::routing_thread] Connect");

                        if let Err(errors) = lock!(INIT).validate() {
                            error!("[bot::routing_thread] ❌ Attempted to connect but init data was not valid. Errors: {:?}", errors);
                            return;
                        }

                        let server_address = crate::CONFIG
                            .connection_url
                            .to_socket_addrs()
                            .unwrap()
                            .next()
                            .unwrap();

                        if !matches!(crate::CONFIG.env, Env::Test) {
                            debug!(
                                "[bot#connect] Attempting to connect to esm_bot at {server_address}"
                            );
                        }

                        let handler = lock!(HANDLER);
                        match handler
                            .network()
                            .connect(Transport::FramedTcp, server_address)
                        {
                            Ok((e, _)) => {
                                *lock!(ENDPOINT) = Some(e);
                            }
                            Err(e) => {
                                error!(
                                    "[bot::routing_thread] ❌ Failed to connect to esm_bot - {e}"
                                );
                            }
                        }
                    });
                }
                BotRequest::Send(message) => {
                    tokio::spawn(async {
                        trace!("[bot::routing_thread] Send");
                        match send(*message) {
                            Ok(_) => trace!("[bot#send_to_bot] Sent"),
                            Err(e) => error!("[bot#send_to_bot] {e}"),
                        }
                    });
                }

                BotRequest::Initialize(init) => {
                    tokio::spawn(async {
                        trace!("[bot::routing_thread] Initialize");

                        *lock!(INIT) = init;

                        // Now that we have the init data, tell ourselves to try to connect
                        if let Err(e) = BotRequest::connect() {
                            error!("[bot::routing_thread] ❌ {e}");
                        }
                    });
                }
                c => {
                    error!("[bot::routing_thread] Cannot process - Client does not respond to {c}")
                }
            }
        }
    });
}

fn listener_thread(listener: NodeListener<NetworkSignal>) {
    let task = listener.for_each_async(|event| match event {
        node::NodeEvent::Network(event) => match event {
            NetEvent::Accepted(_, _) => unreachable!(),
            NetEvent::Connected(_, connected) => {
                crate::TOKIO_RUNTIME.block_on(async {
                    tokio::spawn(async move {
                        if let Err(e) = on_connect(connected).await {
                            error!("[bot#on_connect] {e}");
                        }
                    });
                });
            }
            NetEvent::Disconnected(_) => {
                crate::TOKIO_RUNTIME.block_on(async {
                    tokio::spawn(async move {
                        if let Err(e) = on_disconnect().await {
                            error!("[bot#on_disconnect] {e}");
                        }
                    });
                });
            }
            NetEvent::Message(_, incoming_data) => {
                let incoming_data = incoming_data.to_owned();

                crate::TOKIO_RUNTIME.block_on(async {
                    tokio::spawn(async move {
                        if let Err(e) = on_message(incoming_data).await {
                            error!("[bot#on_message] {e}");
                        }
                    });
                });
            }
        },
        node::NodeEvent::Signal(signal) => match signal {
            NetworkSignal::Init => {
                let message = Message::new(Type::Init).set_data(Data::Init(lock!(INIT).clone()));

                if let Err(e) = BotRequest::send(message) {
                    error!("[bot#listener_thread] Error while sending init message. {e}")
                }
            }
        },
    });

    *lock!(LISTENER_TASK) = Some(task);
}

fn send(mut message: Message) -> ESMResult {
    let mut token = lock!(TOKEN_MANAGER).clone();

    if !token.reload().valid() {
        return Err("❌ Cannot send - Invalid \"esm.key\" detected - Please re-download your server key from the admin dashboard (https://esmbot.com/dashboard).".into());
    }

    // Add the server ID if there is none
    if message.server_id.is_none() {
        message.server_id = Some(token.id_bytes().to_vec());
    }

    if !matches!(message.message_type, Type::Init) {
        debug!("[bot::send] {}", message);
    }

    // Convert the message to bytes so it can be sent
    let bytes = match message.as_bytes(token.key_bytes()) {
        Ok(bytes) => bytes,
        Err(error) => return Err(format!("❌ {error}").into()),
    };

    drop(token);

    let endpoint = *lock!(ENDPOINT);
    let handler = lock!(HANDLER);

    // Make sure we are connected first
    if !ready(&handler, endpoint) {
        return Err(
            "❌ Cannot send message - We are not connected to the bot at the moment".into(),
        );
    }

    match handler.network().send(endpoint.unwrap(), &bytes) {
        SendStatus::Sent => {
            trace!("[bot::send] {} - Sent", message.id);
            Ok(())
        }
        SendStatus::MaxPacketSizeExceeded => Err(format!(
            "❌ Cannot send - Message is too large. Size: {}. Message: {message:?}",
            bytes.len()
        )
        .into()),
        s => Err(
            format!("❌ Cannot send - We are not connected to the bot at the moment: {s:?}").into(),
        ),
    }
}

fn ready(handler: &NodeHandler<NetworkSignal>, endpoint: Option<Endpoint>) -> bool {
    if endpoint.is_none() {
        trace!("[bot::ready] Endpoint is none");
        return false;
    }

    if !CONNECTED.load(Ordering::SeqCst) {
        trace!("[bot::ready] Not connected");
        return false;
    }

    if !handler.is_running() {
        trace!("[bot::ready] Handler is not running");
        return false;
    }

    match handler.network().is_ready(endpoint.unwrap().resource_id()) {
        Some(b) => match b {
            true => true,
            false => {
                trace!("[bot::ready] Endpoint not connected");
                false
            }
        },
        None => {
            trace!("[bot::ready] Endpoint not has been disconnected");
            false
        }
    }
}

async fn on_connect(connected: bool) -> ESMResult {
    if !connected {
        return on_disconnect().await;
    };

    CONNECTED.store(true, Ordering::SeqCst);
    RECONNECTION_COUNT.store(0, Ordering::SeqCst);

    Ok(())
}

async fn on_message(incoming_data: Vec<u8>) -> ESMResult {
    let mut token = lock!(TOKEN_MANAGER);
    if !token.reload().valid() {
        return Err("❌ Cannot process inbound message - Invalid \"esm.key\" detected - Please re-download your server key from the admin dashboard (https://esmbot.com/dashboard).".into());
    }

    let message = match Message::from_bytes(&incoming_data, token.key_bytes()) {
        Ok(message) => {
            drop(token);
            debug!("[bot#on_message] {message}");
            message
        }
        Err(e) => return Err(format!("❌ {e}").into()),
    };

    if !message.errors.is_empty() {
        let error = message
            .errors
            .iter()
            .map(|e| format!("❌ {}", e.error_content))
            .collect::<Vec<String>>()
            .join("\n");

        return Err(error.into());
    }

    match message.message_type {
        Type::Init => {
            if crate::READY.load(Ordering::SeqCst) {
                return Err("❌ Client is already initialized".into());
            }

            ArmaRequest::call("post_initialization", message)
        }
        Type::Query => ArmaRequest::query(message),
        Type::Arma => ArmaRequest::call("call_function", message),
        Type::Test => BotRequest::send(message),
        Type::Ping => BotRequest::send(message.set_type(Type::Pong)),
        _ => Err(format!(
            "❌ Message type \"{:?}\" has not been implemented yet",
            message.message_type
        )
        .into()),
    }
}

async fn on_disconnect() -> ESMResult {
    if !matches!(crate::CONFIG.env, Env::Test) {
        warn!("[bot#on_disconnect] Lost connection with the bot");
    }

    CONNECTED.store(false, Ordering::SeqCst);
    crate::READY.store(false, Ordering::SeqCst);

    tokio::spawn(async {
        // Get the current reconnection count and calculate the wait time
        let current_count = RECONNECTION_COUNT.load(Ordering::SeqCst);
        let time_to_wait = match crate::CONFIG.env {
            Env::Test => 0.25,
            Env::Development => 3.0,
            _ => (current_count * 15) as f32,
        };

        let time_to_wait = Duration::from_secs_f32(time_to_wait);
        warn!(
            "[on_disconnect] ⚠ Lost connection to the bot - Attempting reconnect in {:?}",
            time_to_wait
        );

        // Sleep a max of 5 minutes
        if current_count <= 20 {
            // Increase the reconnect counter by 1
            RECONNECTION_COUNT.fetch_add(1, Ordering::SeqCst);
        }

        if let Err(e) = BotRequest::connect() {
            error!("[bot::on_disconnect] ❌ {e}");
        }
    });

    Ok(())
}
