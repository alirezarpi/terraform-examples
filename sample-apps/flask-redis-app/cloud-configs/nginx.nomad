job "nginx" {
  datacenters = ["dc-aws-1"]

  type = "service"
  
  group "nginx" {
    count = 7

    network {
      port "http" {
          to = 8080
      }
      port "https" {
          to= 443
      }
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "nginx"
        ports = ["http", "https"]
        volumes = [
          "custom/default.conf:/etc/nginx/conf.d/default.conf"
        ]
      }

      template {
        data = <<EOH
          server {
            listen 8080;
            server_name nginx.service.consul;
            location /nginx {
              root /local/data;
            }
          }
        EOH
        destination = "custom/default.conf"
      }
      # consul kv put features/demo 'Consul Rocks!'
     template {
        data = <<EOH
        Nomad Template example (Consul value)
        <br />
        <br />
        {{ if keyExists "features/demo" }}
        Consul Key Value:  {{ key "features/demo" }}
        {{ else }}
          Good morning.
        {{ end }}
        <br />
        <br />
        Node Environment Information:  <br />
        node_id:     {{ env "node.unique.id" }} <br/>
        datacenter:  {{ env "NOMAD_DC" }}
        EOH
        destination = "local/data/nginx/index.html"
      }

      resources {
        cpu    = 100 
        memory = 128
      }
      
      service {
        name = "nginx"
        tags = [ "nginx", "web", "urlprefix-/nginx" ]
        port = "http"
        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
