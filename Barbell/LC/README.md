# Barbell

Barbell is a load generator for latency-critical (LC) applications. It simulates real-world workloads by sending and receiving request at a certain frequency while measuring metrics such as tail latency and throughput. It is usually used to evaluate the performance of a target service in a comprehensive and quantitative way.

## Why Barbell?

### Full Support of Load Generation Modes

Barbell supports all the 3 common load generation modes, that developers usually choose for different cases:

- **Open-Loop**
    - With QPS known, send requests on the scheduled time no matter if the previous requests receive response or not.
    - focus on the latency under huge number of requests arrive at the same time
- **Close-Loop**
    - With QPS known, construct a request on the scheduled time. Send if the previous request receives response and
      block otherwise.
    - focus on the stable latency under small number of requests arrive at the same time
- **Stress Test**
    - No need for QPS, immediately send another request once the previous request receives its response to reach the
      limit of server.
    - focus on the peak QPS that the server application could achieve and the corresponding latency

### Unified System for All Kinds of Load Applications

Nearly all the existing load generator focus on one or a sub-category LC applications (mutilate for Memcached, sysbench
for MYSQL). To make life easier, Barbell provides both general logics for load generation and
customized protocol class interface for application-specific logic, including request content generator and application
protocol (the format of request body and the way to parse the response from server).

Some supported applications are listed below:

| Redis/KeyDB | Memcached |  MYSQL   |  Nginx   |  Kafka   |
|:-----------:|:---------:|:--------:|:--------:|:--------:|
|  &#10004;   | &#10004;  | &#10004; | &#10004; | &#10004; |

### Highly-Customized Load Generation

Load varies largely from application to application, and Barbell can be customized for all kinds of loads and
applications. For detailed customizable items, please refer to the section of [Launching Barbell](#launching-barbell).

## Installation

### Prerequisite

- **python3**
    - numpy, pandas, matplotlib, fitter, scipy, scikit-learn
- **lua5.1**
    - luajit5.1-0, luarocks
- **gcc/g++** >= 7.3.0
- **cmake** >= 3.14

Barbell has been tested to run on the following environments:

### Ubuntu (20.04 or later LTS Release)

#### Client

```bash
apt-get update

# Python Prerequisite
apt-get install python3 python3-dev python3-pip
pip install numpy pandas matplotlib scipy fitter scikit-learn

# Barbell Core
apt-get install sysstat libyaml-cpp-dev zlib1g-dev libboost-all-dev libzmq3-dev libevent-dev
apt-get install libunwind8-dev libgoogle-glog-dev libssh-dev libssl-dev libboost-program-options-dev

# Application Protocol Extension
apt-get install librdkafka-dev libmysqlcppconn-dev

# lua-related
apt-get install lua5.1 luajit lua5.1.0-dev luarocks
luarocks install csv
luarocks install luasocket
luarocks install luafilesystem
luarocks install --server=https://luarocks.org/dev luaffi

# [Updated on July 14th, 2024]
apt-get install libyaml-dev
luarocks install lyaml
```

#### Server

```bash
# Redis
## Prerequisite
apt-get install lsb-release
## Install on Ubuntu/Debian
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
sudo apt-get update
sudo apt-get install redis
# Memcached
apt-get install memcached
# MYSQL
apt-get install mysql-server
# Nginx
apt-get install nginx
```

### Docker Approach for Other Systems

Note that please install docker-ce, otherwise, docker pull may issue "missing signature" error.

#### Build from Dockerfile

```bash
# Barbell executable has already been built in this image
cd /path/to/Barbell/LC
docker build -t barbell:latest .
docker run -itd --name barbell barbell:latest bash
docker exec -it barbell bash
```

#### Pull image from Huawei Shuhai Lab Docker Repo (TODO)

```bash
# Pull from the Huawei shuhai lab docker repository
docker pull barbell:v2
docker images
docker run -itd --name barbell <image_id> bash
docker start <container id>
docker exec -it <container id> bash
```

## Launching Barbell

Before launching Barbell, the source codes need to be compiled first.

### Compilation

```bash
# Compilation
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j6
```

### Execution & Configuration

For now, Barbell accepts configuration parameters from a YAML file by `--yaml`. Only for MySQL service, an extra Lua script (by `--lua`) is required to configure the details of the database and transactions to query. The `--lua-ir` is a potential feature under development currently, and should not be used for now.

Apart from the 3 options, like `sysbench`, a command should be specified to tell Barbell what to do. The command can have 3 available values:
- `prepare`: preload the dataset/database before load generation
- `run`: launch the load generation
- `cleanup`: cleanup the dataset/database after load generation

**Note:** Up to now, four applications (`Redis`, `Memcached`, `KeyDB`, `MySQL`) support `prepare` and `cleanup` command, and the others two (`Nginx` and `Kafka`(both producer and consumer)) do not support.

```bash
mini16% ./src/barbell --help
Barbell is a multi-pass and general-purpose load generator for multiple cloud applications.
Usage: barbell [--yaml/--lua-ir filepath] [--lua filepath] prepare/run/cleanup
It accepts the following options:
  -h [ --help ]         Print Help Documentation
  --yaml arg            YAML configuration file path of loadgen params
  --lua arg             Lua script to customize prepare/run/cleanup and request
                        content (Optional except for MYSQL)
  --lua-ir arg          Lua script for IR pass (if you use lua-ir as 
                        configuration, you should not use yaml at the same 
                        time) (It is an advanced feature, do not use for basic 
                        task if you do not need dynamic load translation like 
                        from cpu_util to qps)

```

#### YAML Configuration File

A sample YAML configuration file is shown below to do load generation for Redis service running on `localhost:6379`. For some of the details inside, it asks Barbell to perform `Open-Loop` load generation with 2 clients (each client launches 4 threads), and lasts for 45 seconds (plus 5s warmup and 5s cooldown). As for the workload, it is a sequence of QPS trace in normal distribution with mean = 100k and standard deviation (stddev) as 500.

More sample YAML configuration files can be found under [Sample YAML Configuration Files](./config) and [Load Generation Examples](./examples).

```yaml
Server:
  # Type of service for load generation
  # |- Can be 'redis', 'memcached', 'keydb', 'mysql', 'nginx', 'kafka'
  Type: redis
  # IP Address of the target server
  # |- Can be any IPv4 or simply 'localhost'
  IP: 127.0.0.1
  # Port of service on the target server
  Port: 6379      
  Auth:
    # Username to login the service
    # |- Enter 'none' if no auth is needed
    UserName: barbell
    # Password to login the service
    # |- Enter 'none' if no auth is needed
    Password: barbell   

Client:
  # Mode of how the workload is issued
  # |- Can be 'open', 'close' 'stress'
  Mode: open
  # Enable distributed clients or not.
  # |- Can only be 'false' for now
  Distributed: false
  # Number of clients to launch (not exactly the number of threads)
  # |- A client launches one thread in closed-loop and 2 threads in open-loop
  # |- For closed-loop and stress, the number of threads = the number of clients
  # |- For open-loop, the number of threads = the number of clients * 2
  ThreadsPerNode: 2
  # One client can host several connections for I/O
  ConnectionsPerThread: 4
  # [Optional] Maximum number of outstanding requests per connection
  # |- default: 100 per connection
  MaxOutstandingRequests: 1000

LatencyMeasurement:
  # Maximum timeout for an outstanding request
  # |- Should be positive
  # |- Set -1 for INT64_MAX (almost INF)
  MaxRequestTimeout: 10000000

StatisticsLogging:
  # Whether to enable statistics logging
  # |- Should always be 'true'
  Enable: true
  # The time interval to log statistics of load generation
  # |- Only '1' is used for testing
  PrintInterval: 1
  # Percentile latency to measure
  # |- can be a list of values concated by ',', no space in between
  # |- values can be fractional (e.g., 99.9)
  PercentileLatency: 50,75,90,99
  # The directory of output files by Barbell
  # |- The exact directory = RootDir/DirName
  Output:
    # Parent directory of the output directory
    # |- default: Barbell/LC/build/src/experiment_results/barbell
    RootDir: default
    # Name of the directory where output files are stored
    # |- default: automatically generate one according to the YAML configuration
    DirName: default
  ServerResourceUtilization:
    SshAuth:
      # Username to login target server
      # |- Cannot be 'none'
      UserName: yuang
      # Password to login target server
      # |- Cannot be 'none'
      Password: fghjkl;'
    # Server-side resources to monitor
    # |- can only be 'cpu' for now
    DataToCollect: cpu

LoadCustomization:
  RequestInterval:
    # Type of inter-arrival distribution
    # |- Can be 'fixed' or 'poisson'
    Type: fixed
  # Total duration = warmup + formal + cooldown
  Duration:
    # Duration of warmup stage (in seconds)
    # |- In this stage, send & recv but not recorded in final output
    Warmup: 5
    # Duration of Formal stage (in seconds)
    # |- In this stage, send & recv and are recorded in the final output
    Formal: 10
    # Duration of Cooldown stage (in seconds)
    # |- In this stage, do not send any more, but receive outstanding requests
    Cooldown: 5
  Pattern:
    # How the workload is generated
    # |- Can be 'synthetic' or 'replay'
    # |- 'synthetic' generates periodic workload with configurable stages
    # |-- 'StagesEachPeriod' should be filled for 'synthetic'
    # |- 'QpsCsvFilePath' should be filled for 'replay'
    Type: synthetic
    Reproduce:
      QpsCsvFilePath: /home/lemaker/open-source/Lab/load_generator/Barbell/LC/examples/vary_cpu_utilization/target_cpu_qps.csv
    Periodical: # The periodical pattern is the default setting. Set 'periods_to_run' as 1 if the trace is not periodical.
      PeriodsToRun: 1   # (float) Number of periods to run during formal stage
      StagesEachPeriod: # A list of load stages. The stages are executed in order.
        # Name/Alias of the load stage
        # |- only to distinguish stages, no influence to load generation at all
        - Name: day
          QPS:
            # Type of QPS Distribution
            # |- Available values to choose from:
            # |- 'fixed', 'uniform', 'normal', 'exponential', 'chi-square'
            # |- 'gamma', 'poisson', 'gennorm', 'alpha', 'exponnorm'
            Model: normal
            # Mean of QPS (used to set parameters of distribution)
            Mean: 80000
            # Standard deviation of QPS (used to set parameters of distribution)
            # |- Note: for some distributions, mean and stddev must follow certain relationship, and error may occurs
            Stddev: 0
          # percentage of duration of this stage (in floating format)
          # |- the duration percentages of all stages should sum up to 1
          Duration: 0.60
        - Name: night
          QPS:
            Model: gennorm
            Mean: 50              # Should be kept to avoid parsing error
            Stddev: 0             # Should be kept to avoid parsing error
            GenNormMiu: 37335.0   # [Optional] GenNorm only
            GenNormAlpha: 9484.0  # [Optional] GenNorm only
            GenNormBeta: 1.44     # [Optional] GenNorm only
            AlphaLocal: 1835      # [Optional] Alpha only
            AlphaScale: 4236      # [Optional] Alpha only
            AlphaAlpha: 2.04      # [Optional] Alpha only
            ExponNormLocal: 15.0  # [Optional] ExponNorm only
            ExponNormScale: 8.37  # [Optional] ExponNorm only
            ExponNormK: 3.22      # [Optional] ExponNorm only
          Duration: 0.4


RequestContentCustomization:
  # Appplicable for Redis/Memcached/KeyDB
  KeyValue:
    # Rate of GETs among all requests
    GetRatio: 0.9
    # Prefix string of all keys
    # |- Keys = KeyPrefix .. key_index .. LOREM_IPSUM
    KeyPrefix: "Barbell_key_"
    # Total number of key indices to randomly select from
    # |- key_index = [0, KeyRange)
    # |- the key_index is bit-aligned (e.g., 001 and 100)
    KeyRange: 10000
    # Length of each key
    KeySize: 100
    # Length of each value
    ValueSize: 2000
  # Applicable for MySQL
  Mysql:
    # Schema name for load generation
    # |- It is suggested to be different from other schemas
    # |- because Barbell will delete it for 'cleanup' command
    Schema: sbtest
  # Applicable for Nginx
  Nginx:
    # Root path of URLs of generated webpages (kept for backwards compatibility)
    TargetURL: "http://localhost:80"
    # Root path of URLs of generated webpages (overwrite value in "TargetURL")
    RootURL: "http://localhost:80/160"
    # how many sub-webpages to generate as load (eg. RootURL/key_index.html)
    # |- set as -1 if to do load generation of a single URL (TargetURL/RootURL)
    KeyRange: -1
  # Applicable for Kafka (both producer and consumer)
  Kafka:
    # Topic name of Kafka
    Topic: test-topic
    # Consumer group name of Kafka
    Group: test-consumer-group
    # [Optional, Unused] default: 0
    Partition: 0
    MessageKeySize: 100       # [Optional, Unused]
    MessageSize: 1000         # [Optional, Unused]
    TransmitCount: 10000      # [Optional, Unused]
```

##### Load Modes

Unlike other load generators that are implemented for a single mode (e.g., Mutilate for close-loop mode and wrk2 for open-loop mode), Barbell supports 3 commonly used modes:
- `Open-Loop`: allow a large number of in-flight requests and send requests out whenever the scheduled time is reached.
  Usually, open-loop mode can achieve higher throughput (QPS) but the latency is higher as well, especially when the number of in-flight requests increase.
- `Close-Loop`: allow only limited number of in-flight requests (e.g., only 1 in-flight request for each client connection in Barbell). New requests are blocked and sent out until the previous request is completed.
  Usually, close-loop mode achieve lower throughput than open-loop, but the latency is much lower as well.
- `Stress Test`: follows the `Close-Loop` mode, but automatically issue a new request once the previous one is completed. In contrast, `Close-Loop` only sends request out when the scheduled time is reached and the previous request is completed. 
  Stress test mode is commonly used to figure out the upper-bound throughput of the server by continuously issuing requests. It achieves the highest throughput than any `Close-Loop` mode under the same resource constraint.

##### Distributions

To simulate various types of workload, Barbell supports the following distributions to synthesize QPS trace, that can be passes to the YAML configuration file:

- `fixed`
- `normal`
- `uniform`
- `exponential`
- `chi-square`
- `gamma`
- `poisson`
- `gennorm` (Generalized Normal)
- `exponnorm` (Exponential Normal)
- `alpha`

Each distribution needs to set its parameters. For the most common distributions like `normal`, `uniform`, `exponential`, only the mean and standard deviation are required. However, for some more advanced distributions, which turned out to fit the real-workload characteristics, like `gennorm`, `alpha`, and `exponnorm`, some extra settings are needed.

Through an analysis of a number of Redis trace in HuaWei cloud, we find that the QPS (Query Per Second) of Redis
requests approximately follows one of the three distributions: **alpha, gennorm, and exponorm** distributions. We
showcase a number of example fitted parameters of these distributions in the following table. Meanwhile, to perform as
well as the real trace in HuaWei cloud, Barbell generates QPS according to the these distributions. The corresponding
meaning of parameters can be found in Python scipy library, such
as https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.gennorm.html.

| Distribution | Parameters                                   | test_file                                |
|--------------|----------------------------------------------|------------------------------------------|
| alpha        | loc=49.5,alpha=3.55,scale=233.66 (Redis-33)  | src/test/distributions/lele_alpha.cpp    |
| alpha        | loc=1835,alpha=2.04,scale=4236 (Redis-50)    | src/test/distributions/lele_alpha.cpp    |
| gennorm      | local=37335,alpha=9484,beta=1.44  (Redis-50) | src/test/distributions/lele_gennorm.cpp  |
| gennorm      | local=7845, alpha=1878, beta=1.31            | src/test/distributions/lele_gennorm.cpp  |
| exponnorm    | k = 3.22, loc=15,scale=8.37 (Redis-31)       | src/test/distributions/lele_exponorm.cpp |
| exponnorm    | k = 1.4, loc=1481.55,scale=438.85 (Redis-66) | src/test/distributions/lele_exponorm.cpp |

The following snippet shows how to configure these advanced distribution parameters in the YAML file. It simulates a trace close to the Redis-50 in Huawei cloud, having 3 different stages within a period.

```yaml
LoadCustomization:
  RequestInterval:
    Type: poisson     # Distribution type of request interval (can be 'fixed' or 'poisson')
  Duration: # Total duration = warmup + formal + cooldown
    Warmup: 5     # Warmup stage sends requests to server, receiving them but not record the latencies
    Formal: 40     # Formal stage is the real load generation and recording stage
    Cooldown: 5   # Cooldown stage collects unreceived requests in formal stage
  Pattern:
    Type: synthetic
    Reproduce:
      # QpsCsvFilePath: /home/yuang/yuxuan/Barbell/LC/examples/vary_cpu_utilization/target_cpu_qps.csv
      QpsCsvFilePath: /home/yuang/yuxuan/Barbell/LC/cmake-build-release/Redis-Trace-50.csv
      # QpsCsvFilePath: /home/yuang/yuxuan/Barbell/LC/cmake-build-release/test.csv
    Periodical: # The periodical pattern is the default setting. Set 'periods_to_run' as 1 if the trace is not periodical.
      PeriodsToRun: 1   # (float) Number of periods to run during formal stage
      StagesEachPeriod: # A list of load stages. The stages are executed in order.
        - Name: day      # Name of the load stage
          QPS:
            Model: gennorm # Available distributions: [fixed, uniform, normal, gamma, poisson, exponential, chi-square, gennorm, alpha, exponnorm ]
            Mean: 20
            Stddev: 0
            GenNormMiu: 37335.0   # Applicable for GenNorm only
            GenNormAlpha: 9484.0  # Applicable for GenNorm only
            GenNormBeta: 1.44     # Applicable for GenNorm only
            AlphaLocal: 1835      # Applicable for Alpha only
            AlphaScale: 4236    # Applicable for Alpha only
            AlphaAlpha: 2.04      # Applicable for Alpha only
            ExponNormLocal: 15.0  # Applicable for ExponNorm only
            ExponNormScale: 8.37  # Applicable for ExponNorm only
            ExponNormK: 3.22      # Applicable for ExponNorm only
          Duration: 0.70   # Percentage of this stage in floating format
        - Name: night
          QPS:
            Model: alpha
            Mean: 50
            Stddev: 0
            GenNormMiu: 37335.0   # Applicable for GenNorm only
            GenNormAlpha: 9484.0  # Applicable for GenNorm only
            GenNormBeta: 1.44     # Applicable for GenNorm only
            AlphaLocal: 1835      # Applicable for Alpha only
            AlphaScale: 4236    # Applicable for Alpha only
            AlphaAlpha: 2.04      # Applicable for Alpha only
            ExponNormLocal: 15.0  # Applicable for ExponNorm only
            ExponNormScale: 8.37  # Applicable for ExponNorm only
            ExponNormK: 3.22      # Applicable for ExponNorm only
          Duration: 0.2
        - Name: burst
          QPS:
            Model: exponnorm
            Mean: 60000
            Stddev: 0
            GenNormMiu: 37335.0   # Applicable for GenNorm only
            GenNormAlpha: 9484.0  # Applicable for GenNorm only
            GenNormBeta: 1.44     # Applicable for GenNorm only
            AlphaLocal: 1835      # Applicable for Alpha only
            AlphaScale: 4236    # Applicable for Alpha only
            AlphaAlpha: 2.04      # Applicable for Alpha only
            ExponNormLocal: 15.0  # Applicable for ExponNorm only
            ExponNormScale: 8.37  # Applicable for ExponNorm only
            ExponNormK: 3.22      # Applicable for ExponNorm only
          Duration: 0.1
```

#### Lua Script (MySQL Only)

Like `sysbench`, a Lua script is needed to configure the database and transactions for MySQL service. Here shows a sample [oltp_point_select.lua](./config/lua/oltp/oltp_point_select.lua) to send read-only point select queries to the server. The format is almost the same with sysbench, but simpler. Users can customize the content inside the transactions by configuring the parameters under `sysbench.opt`. An example is [oltp.lua](./config/lua/oltp/oltp.lua).

```lua
-- ----------------------------------------------------------------------
-- OLTP Point Select benchmark
-- ----------------------------------------------------------------------

local current_file_path = debug.getinfo(1, "S").source:sub(2)
local common_file_directory = current_file_path:match("(.*[/\\])")
package.path = package.path .. ";" .. common_file_directory .. "?.lua"
package.path = ";./?.lua" .. package.path
require("oltp_common")

sysbench = {
    rand = {},
    opt = {
        schema = "barbell",
        table_size = 10000,
        range_size = 100,
        tables = 4, -- table index starts from 1, not 0
        point_selects = 10,
        simple_ranges = 1,
        sum_ranges = 1,
        order_ranges = 1,
        distinct_ranges = 1,
        index_updates = 1,
        non_index_updates = 1,
        delete_inserts = 1,
        range_selects = true,
        auto_inc = true,
        create_table_options = "",
        skip_trx = false,
        secondary = false,
        create_secondary = true,
        reconnect = 0,
        mysql_storage_engine = "innodb",
    }
}

-- @Note: see preload(table_idx) and cleanup() global functions in oltp.common

-- plugged in request() function in Barbell loadgen
function event()
    execute_point_selects(get_table_num())
end
```

## Code Style

clang-format is used as the code formatter in this project with the detailed configuration
file [.clang-format](./.clang-format).

If you use CLion as your IDE, you need to manually do two settings:

1. Setting --> Editor --> Code Style --> Click 'Enable ClangFormat (only for C/C++/Objective-C)'
2. Setting --> Version Control --> Commit --> Before commit --> click 'refactor codes'
