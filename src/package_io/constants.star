EL_TYPE = struct(
    gzond="gzond",
)

CL_TYPE = struct(
    qrysm="qrysm",
)

VC_TYPE = struct(
    qrysm="qrysm",
)

REMOTE_SIGNER_TYPE = struct(
    web3signer="web3signer",
    clef="clef",
)

GLOBAL_LOG_LEVEL = struct(
    info="info",
    error="error",
    warn="warn",
    debug="debug",
    trace="trace",
)

CLIENT_TYPES = struct(
    el="execution",
    cl="beacon",
    validator="validator",
    remote_signer="remote-signer",
)

TCP_DISCOVERY_PORT_ID = "tcp-discovery"
UDP_DISCOVERY_PORT_ID = "udp-discovery"
RPC_PORT_ID = "rpc"
WS_RPC_PORT_ID = "ws-rpc"
WS_PORT_ID = "ws"
HTTP_PORT_ID = "http"
PROFILING_PORT_ID = "profiling"
VALIDATOR_HTTP_PORT_ID = "http-validator"
METRICS_PORT_ID = "metrics"
ENGINE_RPC_PORT_ID = "engine-rpc"
ENGINE_WS_PORT_ID = "engine-ws"
ADMIN_PORT_ID = "admin"
RBUILDER_PORT_ID = "rbuilder-rpc"
LITTLE_BIGTABLE_PORT_ID = "littlebigtable"
VALDIATOR_GRPC_PORT_ID = "grpc"

VALIDATING_REWARDS_ACCOUNT = "Q8943545177806ED17B9F23F0a21ee5948eCaa776"
MAX_QNR_ENTRIES = 20
MAX_QNODE_ENTRIES = 20

ARCHIVE_MODE = True

GENESIS_DATA_MOUNTPOINT_ON_CLIENTS = "/network-configs"
GENESIS_CONFIG_MOUNT_PATH_ON_CONTAINER = GENESIS_DATA_MOUNTPOINT_ON_CLIENTS

VALIDATOR_KEYS_DIRPATH_ON_SERVICE_CONTAINER = "/validator-keys"

CLEF_KEYSTORE_DIRPATH_ON_SERVICE_CONTAINER = "/clef-keystore"

JWT_MOUNTPOINT_ON_CLIENTS = "/jwt"
JWT_MOUNT_PATH_ON_CONTAINER = JWT_MOUNTPOINT_ON_CLIENTS + "/jwtsecret"

KEYMANAGER_MOUNT_PATH_ON_CLIENTS = "/keymanager"
KEYMANAGER_MOUNT_PATH_ON_CONTAINER = (
    KEYMANAGER_MOUNT_PATH_ON_CLIENTS + "/keymanager.txt"
)

MOCK_MEV_TYPE = "mock"
FLASHBOTS_MEV_TYPE = "flashbots"
MEV_RS_MEV_TYPE = "mev-rs"
COMMIT_BOOST_MEV_TYPE = "commit-boost"
DEFAULT_DORA_IMAGE = "ethpandaops/dora:latest"
DEFAULT_ASSERTOOR_IMAGE = "ethpandaops/assertoor:latest"
DEFAULT_SNOOPER_IMAGE = "ethpandaops/rpc-snooper:latest"
DEFAULT_QRL_GENESIS_GENERATOR_IMAGE = (
    "qrledger/qrysm:qrl-genesis-generator-latest"
)
DEFAULT_FLASHBOTS_RELAY_IMAGE = "flashbots/mev-boost-relay:0.29.2a3"
DEFAULT_FLASHBOTS_BUILDER_IMAGE = "ethpandaops/reth-rbuilder:develop"
DEFAULT_FLASHBOTS_MEV_BOOST_IMAGE = "flashbots/mev-boost"
DEFAULT_MEV_RS_IMAGE = "ethpandaops/mev-rs:main"
DEFAULT_MEV_RS_IMAGE_MINIMAL = "ethpandaops/mev-rs:main-minimal"
DEFAULT_COMMIT_BOOST_MEV_BOOST_IMAGE = "ghcr.io/commit-boost/pbs:latest"
DEFAULT_MOCK_MEV_IMAGE = "ethpandaops/rustic-builder:main"
DEFAULT_MEV_PUBKEY = "0xa55c1285d84ba83a5ad26420cd5ad3091e49c55a813eee651cd467db38a8c8e63192f47955e9376f6b42f6d190571cb5"
DEFAULT_MEV_SECRET_KEY = (
    "0x607a11b45a7219cc61a3d9c5fd08c7eebd602a6a19a977f8d3771d5711a550f2"
)

DEFAULT_MNEMONIC = "veto waiter rail aroma aunt chess fiend than sahara unwary punk dawn belong agent sane reefy loyal from judas clean paste rho madam poor pay convoy duty circa hybrid circus exempt splash"

PRIVATE_IP_ADDRESS_PLACEHOLDER = "KURTOSIS_IP_ADDR_PLACEHOLDER"

GENESIS_FORK_VERSION = "0x10000038"

MAX_LABEL_LENGTH = 63

CONTAINER_REGISTRY = struct(
    dockerhub="/",
    ghcr="ghcr.io",
    gcr="gcr.io",
)

NETWORK_NAME = struct(
    mainnet="mainnet",
    ephemery="ephemery",
    kurtosis="kurtosis",
    shadowfork="shadowfork",
)

PUBLIC_NETWORKS = (
    "mainnet",
)

NETWORK_ID = {
    "mainnet": "1",
}

CHECKPOINT_SYNC_URL = {
    "mainnet": "https://beaconstate.info",
    "ephemery": "https://checkpoint-sync.ephemery.ethpandaops.io/",
}

DEPOSIT_CONTRACT_ADDRESS = {
    "mainnet": "Q00000000219ab540356cBB839Cbe05303d7705Fa",
    "ephemery": "Q4242424242424242424242424242424242424242",
}

GENESIS_TIME = {
    "mainnet": 1606824023,
}

VOLUME_SIZE = {
    "mainnet": {
        "gzond_volume_size": 1000000,  # 1TB
        "qrysm_volume_size": 500000,  # 500GB
    },
    "devnets": {
        "gzond_volume_size": 100000,  # 100GB
        "qrysm_volume_size": 100000,  # 100GB
    },
    "ephemery": {
        "gzond_volume_size": 5000,  # 5GB
        "qrysm_volume_size": 1000,  # 1GB
    },
    "kurtosis": {
        "gzond_volume_size": 5000,  # 5GB
        "qrysm_volume_size": 1000,  # 1GB
    },
}
VOLUME_SIZE["mainnet-shadowfork"] = VOLUME_SIZE["mainnet"]
