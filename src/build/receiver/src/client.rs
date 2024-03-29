use std::net::ToSocketAddrs;
use std::sync::Arc;

use crate::log_reader::LogReader;
use crate::{command::IncomingCommand, transfer::*, write_lock, Command, Database, NetworkCommand};
use crate::{read_lock, BuildError};
use colored::Colorize;
use common::NetworkSend;
use message_io::network::{Endpoint, NetEvent, Transport};
use message_io::node::{self, NodeHandler};
use parking_lot::RwLock;

pub struct Arma {
    pub build_path: String,
    pub server_path: String,
    pub server_args: String,
}

#[derive(Clone)]
pub struct Client {
    pub host: String,
    pub transfers: Arc<RwLock<Transfers>>,
    pub database: Arc<Database>,
    pub arma: Arc<Arma>,
    pub log: Arc<RwLock<LogReader>>,

    handler: Option<NodeHandler<()>>,
    endpoint: Option<Endpoint>,
}

impl Client {
    pub fn new(args: crate::Args) -> Result<Self, BuildError> {
        let transfers = Arc::new(RwLock::new(Transfers::new()));
        let database = Arc::new(Database::new(&args.database_uri)?);
        let log = Arc::new(RwLock::new(LogReader::new(&args)));
        let arma = Arc::new(Arma {
            build_path: args.build_path,
            server_path: args.a3_server_path,
            server_args: args.a3_server_args,
        });

        Ok(Client {
            handler: None,
            endpoint: None,
            host: args.host,
            transfers,
            database,
            arma,
            log,
        })
    }

    pub fn connect(&mut self) {
        let (handler, listener) = node::split::<()>();

        // Move this to an argument that is passed into the program
        let server_addr = self.host.to_socket_addrs().unwrap().next().unwrap();
        let (server, _) = handler
            .network()
            .connect(Transport::FramedTcp, server_addr)
            .unwrap();

        self.handler = Some(handler);
        self.endpoint = Some(server);

        let mut client = self.clone();
        listener.for_each(move |event| match event.network() {
            NetEvent::Connected(_endpoint, established) => {
                if established {
                    println!("{} - Connected to {}", "success".green(), server_addr);
                    client.send(Command::Hello).unwrap();
                } else {
                    println!("{} - Failed to connect to {}", "error".red(), server_addr);
                    client.on_disconnect();
                }
            }
            NetEvent::Accepted(_, _) => unreachable!(),
            NetEvent::Message(_endpoint, input_data) => {
                let mut network_command: NetworkCommand = match serde_json::from_slice(input_data) {
                    Ok(c) => c,
                    Err(e) => {
                        client.send(Command::Error(e.to_string())).unwrap();
                        return;
                    }
                };

                match IncomingCommand::execute(&client, &mut network_command.command) {
                    Ok(command) => {
                        println!("{:?} - {:?}", command, network_command.command);
                        network_command.command = command;
                        client.send_network(network_command);
                    }
                    Err(e) => {
                        println!("Failed - {e} - {:?}", network_command.command);
                        network_command.command = Command::Error(e.to_string());
                        client.send_network(network_command);
                    }
                }
            }
            NetEvent::Disconnected(_endpoint) => {
                client.on_disconnect();
            }
        });
    }

    pub fn send_network(&self, command: NetworkCommand) {
        let data = serde_json::to_vec(&command).unwrap();

        self.handler
            .as_ref()
            .unwrap()
            .network()
            .send(self.endpoint.unwrap(), &data);
    }

    fn on_disconnect(&mut self) {
        write_lock(&self.transfers, |mut writer| {
            writer.clear();
            Ok(true)
        })
        .unwrap();

        read_lock(&self.log, |reader| {
            reader.stop_reads();
            Ok(true)
        })
        .unwrap();

        self.handler.as_ref().unwrap().stop();
    }
}

impl NetworkSend for Client {
    fn send(&self, command: Command) -> Result<Command, BuildError> {
        self.send_network(NetworkCommand::new(command));
        Ok(Command::Success)
    }
}
