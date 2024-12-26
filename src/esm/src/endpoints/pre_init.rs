use super::*;

const BOOT_FAILED_PREFIX: &str = "[pre_init] ❌ Boot failed -";
const BOOT_FAILED_MESSAGE: &str = "[pre_init] ❌ Boot failed - You must fix the above error(s) before Exile Server Manager can boot";

pub fn pre_init(
    callback: Context,
    server_name: String,
    price_per_object: NumberString,
    territory_lifetime: NumberString,
    territory_data: String,
    vg_enabled: bool,
    vg_max_sizes: String,
) {
    // Only allow this method to be called properly once
    if BOOTED.load(Ordering::SeqCst) {
        warn!("[pre_init] ⚠ This endpoint can only be called once. Perhaps your server is boot looping?");
        return;
    }

    let timer = std::time::Instant::now();
    debug!(
        r#"[pre_init]
            server_name: {:?}
            price_per_object: {:?}
            territory_lifetime: {:?}
            territory_data: {:?}
            vg_enabled: {:?}
            vg_max_sizes: {:?}
        "#,
        server_name,
        price_per_object,
        territory_lifetime,
        territory_data,
        vg_enabled,
        vg_max_sizes
    );

    // Router must be initialized outside the async context
    lazy_static::initialize(&ROUTER);

    info!("[pre_init] Exile Server Manager (extension) is initializing");
    info!("[pre_init]   Validating config file...");

    if let Err(e) = CONFIG.validate() {
        error!("{BOOT_FAILED_PREFIX} Invalid config file");
        error!("[pre_init] ❌ {}", e);
        error!("{BOOT_FAILED_MESSAGE}");
        return;
    }

    info!("[pre_init]   Validating initialization package...");

    // Using the data from the a3 server, create a data packet to be used whenever the server connects to the bot.
    let init = Init {
        server_name,
        price_per_object,
        territory_lifetime,
        territory_data,
        vg_enabled,
        vg_max_sizes,
        server_start_time: Utc::now(),
        extension_version: format!(
            "{}+{}",
            env!("CARGO_PKG_VERSION"),
            std::include_str!("../../.build-sha")
        ),
    };

    if let Err(errors) = init.validate() {
        debug!("{:#?}", init);
        error!("{BOOT_FAILED_PREFIX} Invalid initialization data provided");

        for error in errors {
            error!("[pre_init] ❌ {error}");
        }

        error!("{BOOT_FAILED_MESSAGE}");
        return;
    }

    info!("[pre_init]   Connecting to the database...");
    let connection_result =
        TOKIO_RUNTIME.block_on(async { DATABASE.connect().await });

    if let Err(e) = connection_result {
        error!("{BOOT_FAILED_PREFIX} Failed to connect to the database");
        error!("[pre_init] ❌ {e}");
        error!("{BOOT_FAILED_MESSAGE}");
        return;
    }

    info!("[pre_init]   Negotiating with Arma...");
    if let Err(e) = ArmaRequest::initialize(callback) {
        error!("{BOOT_FAILED_PREFIX} Failed to initialize Arma components");
        error!("[pre_init] ❌ {e}");
        error!("{BOOT_FAILED_MESSAGE}");
        return;
    };

    info!("[pre_init]   Looking up the bot's number...");
    if let Err(e) = BotRequest::initialize(init) {
        error!("{BOOT_FAILED_PREFIX} Failed to initialize bot components");
        error!("[pre_init] ❌ {e}");
        error!("{BOOT_FAILED_MESSAGE}");
        return;
    };

    BOOTED.store(true, Ordering::SeqCst);

    info!(
        "[pre_init] ✅ Initialization completed in {:.2?}",
        timer.elapsed()
    );
}
