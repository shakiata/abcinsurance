Readme
This is a terraform test for a simple load balenced proof of concept azure deployment,  

In Terminal from the Directly run "terraform init"
then run "terraform apply"
this will build the azure asset


                        ┌───────────────────────┐
                        │                       │
                        │                       │
                        │                       │
                        │                       │
                        │  internet WWW         │
                        │                       │
                        │                       │
                        │                       │
                        │                       │
                        │                       │
                        └───────────┬───────────┘
                                    │
                                    │
                                    │
                                    │
                               ┌────┴─────────┐
                               │              │
                               │    ┼         │
                               │   Load       │
                               │   Balancer   │
                               │              │
                               │              │
                               └────┬─────────┘
                                    │
                                    │vnet
┌────────────────────────┐          │
│                        │   nic    │                   ┌──────────────────────────┐
│                       ─┼──────────┤     nic           │                          │
│                        │          └───────────────────┼─                         │
│      vm1               │                              │                          │
│                        │                              │                          │
│                        │                              │       vm2                │
│                        │                              │                          │
│                        │                              │                          │
│                        │                              │                          │
│                        │                              │                          │
│                        │                              │                          │
└────────────────────────┘                              │                          │
                                                        └──────────────────────────┘