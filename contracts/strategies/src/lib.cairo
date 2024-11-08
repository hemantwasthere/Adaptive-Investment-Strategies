mod contracts {
    mod auto_vault;
    mod cl_vault;
    mod cl_token;
}

mod interfaces {
    pub mod IAutoVault;
    pub mod IERC20Camel;
    pub mod IERC4626;
    pub mod oracle;
    pub mod ICLVault;
    pub mod IOracle;
    pub mod IERC20Strat;
    pub mod IEkuboCore;
    pub mod IEkuboPositions;
    pub mod IEkuboPositionsNFT;
}

mod utils {
    pub mod math;
    pub mod helpers;
    pub mod errors;
    pub mod constants;
}

mod components {
    pub mod swap;
}
