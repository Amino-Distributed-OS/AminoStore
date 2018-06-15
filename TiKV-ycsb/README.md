# How to run

- Update ip adresses in all script files
- Install TiKV
- Install Go and setup environement (add to file .profile the following: export GOROOT=<your_go_dir>; export GOPATH=<your_project_dir>; export PATH=$GOPATH/bin:$GOROOT/bin:$PATH)
- Provide ip address of placement driver (PD) you want to connect (edit file /DCAP-Tapir/TiKV-ycsb/src/github.com/pingcap/go-ycsb/db/tikv/raw.go line 40)
- cd /DCAP-Tapir/TiKV-ycsb/src/github.com/pingcap/go-ycsb; make
- Start servers
- Run benchmark
- Stop servers
