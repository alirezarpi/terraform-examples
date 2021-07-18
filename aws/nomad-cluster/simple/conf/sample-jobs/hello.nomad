job "helloapp" {
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

	group "hello" {
		count = 10

		network {
			port "http" {
				to = 8080
			}
		}

		update {
			max_parallel     = 2
			min_healthy_time = "30s"
			healthy_deadline = "2m"
		}

		restart {
			attempts = 2
			interval = "1m"

			delay = "10s"
			mode = "fail"
		}

		task "hello" {
			driver = "docker"

			config {
				image = "gerlacdt/helloapp:v0.1.0"
				ports = ["http"]
			}

			service {
				name = "${TASKGROUP}-service"
				tags = ["global", "hello", "urlprefix-hello.internal/"]
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