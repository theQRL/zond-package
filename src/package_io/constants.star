EL_TYPE = struct(
    gzond="gzond",
)

CL_TYPE = struct(
    qrysm="qrysm",
)

VC_TYPE = struct(
    qrysm="qrysm",
)

REMOTE_SIGNER_TYPE = struct(web3signer="web3signer")

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

VALIDATING_REWARDS_ACCOUNT = "0x8943545177806ED17B9F23F0a21ee5948eCaa776"
MAX_ENR_ENTRIES = 20
MAX_ENODE_ENTRIES = 20

GENESIS_VALIDATORS_ROOT_PLACEHOLDER = "GENESIS_VALIDATORS_ROOT_PLACEHOLDER"

ARCHIVE_MODE = True

GENESIS_DATA_MOUNTPOINT_ON_CLIENTS = "/network-configs"
GENESIS_CONFIG_MOUNT_PATH_ON_CONTAINER = GENESIS_DATA_MOUNTPOINT_ON_CLIENTS

VALIDATOR_KEYS_DIRPATH_ON_SERVICE_CONTAINER = "/validator-keys"

JWT_MOUNTPOINT_ON_CLIENTS = "/jwt"
JWT_MOUNT_PATH_ON_CONTAINER = JWT_MOUNTPOINT_ON_CLIENTS + "/jwtsecret"

KEYMANAGER_MOUNT_PATH_ON_CLIENTS = "/keymanager"
KEYMANAGER_MOUNT_PATH_ON_CONTAINER = (
    KEYMANAGER_MOUNT_PATH_ON_CLIENTS + "/keymanager.txt"
)

DEFAULT_DORA_IMAGE = "ethpandaops/dora:latest"
DEFAULT_ASSERTOOR_IMAGE = "ethpandaops/assertoor:latest"
DEFAULT_SNOOPER_IMAGE = "ethpandaops/rpc-snooper:latest"
DEFAULT_ZOND_GENESIS_GENERATOR_IMAGE = (
    "theQRL/zond-genesis-generator:3.6.0"
)

DEFAULT_MNEMONIC = "giant issue aisle success illegal bike spike question tent bar rely arctic volcano long crawl hungry vocal artwork sniff fantasy very lucky have athlete"

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
    sepolia="sepolia",
    ephemery="ephemery",
    kurtosis="kurtosis",
    shadowfork="shadowfork",
)

PUBLIC_NETWORKS = (
    "mainnet",
    "sepolia",
)

NETWORK_ID = {
    "mainnet": "1",
    "sepolia": "11155111",
    "holesky": "17000",
}

CHECKPOINT_SYNC_URL = {
    "mainnet": "https://beaconstate.info",
    "ephemery": "https://checkpoint-sync.ephemery.ethpandaops.io/",
    "sepolia": "https://checkpoint-sync.sepolia.ethpandaops.io/",
    "holesky": "https://checkpoint-sync.holesky.ethpandaops.io/",
}

GENESIS_VALIDATORS_ROOT = {
    "mainnet": "0x4b363db94e286120d76eb905340fdd4e54bfe9f06bf33ff6cf5ad27f511bfe95",
    "sepolia": "0xd8ea171f3c94aea21ebc42a1ed61052acf3f9209c00e4efbaaddac09ed9b8078",
}

DEPOSIT_CONTRACT_ADDRESS = {
    "mainnet": "0x00000000219ab540356cBB839Cbe05303d7705Fa",
}

GENESIS_TIME = {
    "mainnet": 1606824023,
    "sepolia": 1655733600,
}

VOLUME_SIZE = {
    "mainnet": {
        "gzond_volume_size": 1000000,  # 1TB
        "qrysm_volume_size": 500000,  # 500GB
    },
    "sepolia": {
        "gzond_volume_size": 300000,  # 300GB
        "qrysm_volume_size": 150000,  # 150GB
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
VOLUME_SIZE["sepolia-shadowfork"] = VOLUME_SIZE["sepolia"]
VOLUME_SIZE["holesky-shadowfork"] = VOLUME_SIZE["holesky"]
