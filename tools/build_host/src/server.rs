use message_io::network::{Endpoint, NetEvent, Transport};
use message_io::node::{self, NodeHandler, NodeTask};
use parking_lot::RwLock;

use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::Duration;

use crate::NetworkCommands;

#[derive(Clone)]
pub struct Server {
    pub connected: Arc<AtomicBool>,
    server_task: Arc<Option<NodeTask>>,
    handler: Option<NodeHandler<()>>,
    endpoint: Arc<RwLock<Option<Endpoint>>>,
    waiting_for_response: Arc<AtomicBool>,
}

impl Server {
    pub fn new() -> Self {
        Server {
            connected: Arc::new(AtomicBool::new(false)),
            waiting_for_response: Arc::new(AtomicBool::new(false)),
            server_task: Arc::new(None),
            handler: None,
            endpoint: Arc::new(RwLock::new(None)),
        }
    }

    pub fn start(&mut self) {
        let (handler, listener) = node::split::<()>();

        let listen_addr = "0.0.0.0:6969";
        handler
            .network()
            .listen(Transport::FramedTcp, listen_addr)
            .unwrap();

        let builder = self.clone();
        let task = listener.for_each_async(move |event| match event.network() {
            NetEvent::Connected(_, _) => unreachable!(),
            NetEvent::Accepted(_endpoint, _id) => {}
            NetEvent::Message(endpoint, input_data) => {
                let message: NetworkCommands = bincode::deserialize(input_data).unwrap();
                if let NetworkCommands::Hello = message {
                    *builder.endpoint.write() = Some(endpoint);
                    builder.connected.store(true, Ordering::SeqCst);
                } else {
                    builder.waiting_for_response.store(false, Ordering::SeqCst);
                }
            }
            NetEvent::Disconnected(_endpoint) => {}
        });

        self.server_task = Arc::new(Some(task));
        self.handler = Some(handler);
    }

    pub fn stop(&mut self) {
        self.handler.as_ref().unwrap().stop();
    }

    pub fn send(&self, command: NetworkCommands) {
        let data = bincode::serialize(&command).unwrap();
        self.handler
            .as_ref()
            .unwrap()
            .network()
            .send(self.endpoint.read().unwrap(), &data);

        self.waiting_for_response.store(true, Ordering::SeqCst);
        while self.waiting_for_response.load(Ordering::SeqCst) {
            std::thread::sleep(Duration::from_secs_f32(0.5))
        }
    }
}