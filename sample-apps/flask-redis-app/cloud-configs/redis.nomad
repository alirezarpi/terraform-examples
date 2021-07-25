job "redis" {
	region = "region-aws-1"
	datacenters = ["dc-aws-1"]
    type = "service"

    update {
        max_parallel = 1
        min_healthy_time = "10s"

        healthy_deadline = "3m"
        auto_revert = false

        canary = 0
    }

    group "cache" {
        count = 1

        restart {
            attempts = 10
            interval = "5m"
            delay = "25s"
            mode = "delay"
        }

        network {
            port "db" {
                to = 6379
            }
        }

        ephemeral_disk {
            size = 300
        }

        task "redis" {
            driver = "docker"

            config {
                image = "redis:3.2"
                ports = ["db"]
            }

            resources {
                cpu    = 500
                memory = 256 
            }

            service {
                name = "global-redis-check"
                tags = ["global", "redis", "urlprefix-/redis" ]
                port = "db"
                check {
                    name     = "alive"
                    type     = "tcp"
                    interval = "10s"
                    timeout  = "2s"
                }
            }
        }
    }
}