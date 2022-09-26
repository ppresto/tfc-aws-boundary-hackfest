{
  "service": {
    "name": "api",
    "namespace": "api",
    "port": 9091,
    "token": "${SERVICE_ACL_TOKEN}",
    "tags": ["vm","v1"],
    "meta": {
      "version": "v1"
    },
    "check": {
      "http": "http://localhost:9091/health",
      "method": "GET",
      "interval": "1s",
      "timeout": "1s"
    },
    "connect": {
      "sidecar_service": {
      "port": 20000
       }
    }
  }
}