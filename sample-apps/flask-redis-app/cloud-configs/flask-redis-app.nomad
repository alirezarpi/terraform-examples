job "test-app" {
	region = "region-aws-1"
	datacenters = ["dc-aws-1"]
	type = "service"

	constraint {
		attribute = "${attr.kernel.name}"
		value = "linux"
	}

	update {
		stagger = "10s"
		max_parallel = 1
	}

	group "flask-redis" {
		count = 5

		network {
			port "http" {
				to = 5000
			}
			port "redis" {
				to = 6379
			}
		}
			
		update {
			max_parallel     = 1
			min_healthy_time = "30s"
			healthy_deadline = "2m"
		}

		restart {
			attempts = 2
			interval = "1m"

			delay = "10s"
			mode = "fail"
		}

		task "flask-app" {
			driver = "docker"

			config {
				image = "alirezarpi/flask-redis-app:latest"
				ports = ["http", "redis"]
			}

			service {
				name = "${TASKGROUP}-service"
				tags = ["global", "flask-app", "urlprefix-/app"]
				port = "http"
				check {
                    name = "alive"
                    type = "http"
                    interval = "10s"
                    timeout = "3s"
                    path = "/health"
				}
			}

			resources {
				cpu = 500
				memory = 128
			}

			logs {
			    max_files = 10
			    max_file_size = 15
			}

			kill_timeout = "10s"
		}
	}
}