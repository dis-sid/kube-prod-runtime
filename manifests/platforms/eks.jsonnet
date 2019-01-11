/*
 * Bitnami Kubernetes Production Runtime - A collection of services that makes it
 * easy to run production workloads in Kubernetes.
 *
 * Copyright 2018 Bitnami
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// Top-level file for AWS EKS

local cert_manager = import '../components/cert-manager.jsonnet';
local dex = import '../components/dex.jsonnet';
local edns = import '../components/externaldns.jsonnet';
local nginx_ingress = import '../components/nginx-ingress.jsonnet';
local prometheus = import "../components/prometheus.jsonnet";
local oauth2_proxy = import "../components/oauth2-proxy.jsonnet";
local kube = import '../lib/kube.libsonnet';

{
  config:: error 'no kubeprod configuration',

  // Shared metadata for all components
  kubeprod: kube.Namespace('kubeprod'),

  external_dns_zone_name:: $.config.dnsZone,
  letsencrypt_contact_email:: $.config.contactEmail,
  letsencrypt_environment:: 'staging',

  version: import '../components/version.jsonnet',

  edns: edns {
    deploy+: {
      ownerId: $.external_dns_zone_name,
      spec+: {
        template+: {
          spec+: {
            containers_+: {
              edns+: {
                args_+: {
                  provider: 'aws',
                  'aws-zone-type': 'public',
                  registry: 'txt',
                },
              },
            },
          },
        },
      },
    },
  },

  cert_manager: cert_manager {
    letsencrypt_contact_email:: $.letsencrypt_contact_email,
    letsencrypt_environment:: $.letsencrypt_environment,
  },

  nginx_ingress: nginx_ingress,

  dex: dex {
    ingress+: {
      host: "dex." + $.external_dns_zone_name,
    },
  },

  oauth2_proxy: oauth2_proxy {
    secret+: {
      data_+: {
      client_id: '42ohkq7cmp72akptr0ltomteci',
      client_secret: '1ucuhu0jck7dahhb1n3tail711a6vv8uo92n42d9abi0jncnml28',
      cookie_secret: 'sXXawOw8C4eFoP14jROminFXqFyhonUk',
      }
    },

    deploy+: {
      spec+: {
        template+: {
          spec+: {
            containers_+: {
              proxy+: {
                args_+: {
                  provider: 'oidc',
                  'cookie-secure': 'false',
                  'oidc-issuer-url': 'https://cognito-idp.eu-central-1.amazonaws.com/eu-central-1_P7sIQ92Cd',
                },
              },
            },
          },
        },
      },
    },
  },

  prometheus: prometheus {
    ingress+: {
      host: "prometheus." + $.external_dns_zone_name,
    },
  },
}