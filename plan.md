# LTRXAR-3100 — Multidomain Integration Plan

**Status:** Draft for review (interim file — review and approve before any repo changes are made)
**Last updated:** 2026-05-11
**Lab:** Cisco Live LTRXAR-3100
**Scope:** End-to-end EBGP handoff stitching across three NaC-managed domains — ACI, Catalyst SD-WAN, Catalyst Center (SDA) — with cEdge-01 as the SD-WAN hub.

---

## 1. Goal

Build a multidomain lab where:

- An **ACI** fabric (2 compute leafs + 1 border leaf) hands off two VRFs (PROD, SVCS) over EBGP to a **Catalyst SD-WAN** edge.
- That SD-WAN fabric (2 cEdge routers) transports the segmentation across two service VPNs (VPN 30 CORP, VPN 40 GUEST).
- On the other side, a **Catalyst Center / SDA** fabric (2 edge nodes + 1 border node) hands off two Virtual Networks (Campus, Guest) over EBGP into the same SD-WAN.
- All cross-domain integration lives in a **new `multi-domain/` repo**, leaving each domain repo (`aci/`, `sdwan/`, `catc/`) cleanly responsible for its own fabric foundation.

---

## 2. Topology

```
                       ┌────────────────── ACI fabric (AS 65100) ──────────────────┐
                       │                                                            │
                       │   leaf-401 ─┐                                              │
                       │             ├── VPC pair (compute)                         │
                       │   leaf-402 ─┘                                              │
                       │                                                            │
                       │   leaf-403  (border leaf, no VPC)                          │
                       │      │                                                     │
                       │      │ eth1/1                                              │
                       └──────┼─────────────────────────────────────────────────────┘
                              │
                              │  sub-int 3010  PROD ↔ VPN30   10.100.10.0/30   EBGP 65100↔65200
                              │  sub-int 3020  SVCS ↔ VPN40   10.100.20.0/30   EBGP 65100↔65200
                              │
                       ┌──────▼─────────────────────────────── cEdge-01 (HUB, Site 2) ─┐
                       │      Gi3                                                       │
                       │                                                                │
                       │      ┌────────────────────────────┐                            │
                       │      │     SD-WAN overlay         │   AS 65200                 │
                       │      │   VPN 30 CORP              │                            │
                       │      │   VPN 40 GUEST             │                            │
                       │      └────────────────────────────┘                            │
                       │                                                                │
                       │                                cEdge-02 (Site 3) Gi3 ──────────┘
                                                                          │
                              ┌───────────────────────────────────────────┘
                              │
                              │  sub-int 3030  Campus ↔ VPN30  10.100.30.0/30  EBGP 65001↔65200
                              │  sub-int 3040  Guest  ↔ VPN40  10.100.40.0/30  EBGP 65001↔65200
                              │
                       ┌──────▼─────────────────────────────────────────────────────┐
                       │  BR10 Gi1/0/3  (border node + control plane)               │
                       │                                                            │
                       │   EDGE-01 ─┐                                                │
                       │            ├── fabric edge nodes                            │
                       │   EDGE-02 ─┘                                                │
                       │                                                            │
                       └────────────────── CATC / SDA fabric (AS 65001) ────────────┘
```

---

## 3. Domain Mapping

| ACI VRF | SD-WAN Service VPN | CATC Virtual Network | Role |
|---------|--------------------|----------------------|------|
| PROD    | VPN 30 (CORP)      | Campus               | User / production traffic |
| SVCS    | VPN 40 (GUEST)     | Guest                | Services / guest traffic |

### AS Number Plan (distinct per-domain, ensures distinct AS-paths)

| Domain | ASN |
|---|---|
| ACI fabric | 65100 |
| SD-WAN overlay | 65200 |
| CATC / SDA fabric | 65001 (existing) |

Route from ACI PROD to CATC Campus traverses AS-path `65100 → 65200 → 65001`, fully distinct, no manipulation needed. Wide-open policy: no route-maps, no communities, no prefix-lists for the lab.

---

## 4. IP & Handoff Plan

Single physical link per domain pair; **one dot1q sub-interface per VRF/VPN/VN**; /30 per EBGP session.

### ACI border leaf 403 ↔ cEdge-01 (Site 2)

| Pair | VLAN | Subnet | ACI side | SD-WAN side | EBGP |
|------|------|--------|----------|-------------|------|
| PROD ↔ VPN30 | 3010 | 10.100.10.0/30 | 10.100.10.1 | 10.100.10.2 | 65100 ↔ 65200 |
| SVCS ↔ VPN40 | 3020 | 10.100.20.0/30 | 10.100.20.1 | 10.100.20.2 | 65100 ↔ 65200 |

- Border leaf 403 physical: `eth1/1` (trunk, both VLANs)
- cEdge-01 physical: `GigabitEthernet3` (sub-interfaces `Gi3.3010`, `Gi3.3020`)
- Border leaf 403 router-id: `10.255.100.3`

### CATC BR10 ↔ cEdge-02 (Site 3)

| Pair | VLAN | Subnet | CATC side | SD-WAN side | EBGP |
|------|------|--------|-----------|-------------|------|
| Campus ↔ VPN30 | 3030 | 10.100.30.0/30 | 10.100.30.1 | 10.100.30.2 | 65001 ↔ 65200 |
| Guest  ↔ VPN40 | 3040 | 10.100.40.0/30 | 10.100.40.1 | 10.100.40.2 | 65001 ↔ 65200 |

- BR10 physical: `GigabitEthernet1/0/3`
- cEdge-02 physical: `GigabitEthernet3` (sub-interfaces `Gi3.3030`, `Gi3.3040`)

### Internal subnets (BD / pool / anycast — for reference, owned by domain repos)

| Domain | Object | Subnet (lab) | Notes |
|---|---|---|---|
| ACI | PROD BDs (×6) | 192.168.10.0/24 … 192.168.15.0/24 | BD_VLAN30..35, anycast .1, `public: true` |
| ACI | SVCS BDs (×6) | 192.168.20.0/24 … 192.168.25.0/24 | BD_VLAN40..45, anycast .1, `public: true` |
| CATC | Campus anycast | 192.168.100.0/24 | CampusVN-IPPool, gateway .1 |
| CATC | Guest anycast | 192.168.101.0/24 | GuestVN-IPPool, gateway .1 |

### CATC site hierarchy

`Global/USA/Nevada/Las Vegas` (city) → `Bld A` (building, lat 36.1699, lon -115.1398) → `FLOOR_1`, `FLOOR_2`. Network settings and IP pool reservations live on the Las Vegas city node. BYOD and Printers VNs were removed (only Campus + Guest are stitched into the multidomain handoff).

---

## 5. Repository Structure

```
/srv/work/cl26-ltrxar-3100/
├── aci/                      # domain-local: fabric foundation + standalone tenants PROD, SVCS
├── sdwan/                    # domain-local: SD-WAN overlay foundation (VPN0, VPN512, base feature templates)
├── catc/                     # domain-local: SDA site, IP pools, VNs, edge nodes EDGE01/02
├── ise/                      # domain-local: untouched in this plan
└── multi-domain/             # NEW — orchestrates cross-domain stitching
    ├── plan.md               # this file
    ├── .gitlab-ci.yml        # 3-stage orchestrator: deploy-aci → deploy-catc → deploy-sdwan
    ├── aci/                  # multidomain stitching for ACI side
    │   ├── .gitlab-ci.yml
    │   ├── main.tf
    │   ├── data/
    │   │   ├── node_403_border.nac.yaml
    │   │   └── l3outs_sdwan.nac.yaml
    │   ├── templates/
    │   └── tests/
    ├── sdwan/                # multidomain stitching for SD-WAN side
    │   ├── .gitlab-ci.yml
    │   ├── main.tf
    │   ├── data/
    │   │   ├── sites.nac.yaml                          # cEdge-01 (moved) + cEdge-02 (new)
    │   │   ├── edge_device_templates.nac.yaml          # hub + spoke device templates
    │   │   └── edge_feature_templates.nac.yaml        # BGP + sub-int templates for VPN30/40
    │   ├── templates/
    │   └── tests/
    └── catc/                 # multidomain stitching for CATC side
        ├── .gitlab-ci.yml
        ├── main.tf
        ├── data/
        │   ├── transit.nac.yaml                         # IP_BASED_TRANSIT BGP65200
        │   └── border_BR10.nac.yaml                     # BR10 (moved) with l3_handoffs
        ├── templates/
        └── tests/
```

### Ownership Boundary

To prevent two pipelines from fighting over the same APIC/vManage/CATC object, every object has exactly one owner.

| Object | Owner |
|---|---|
| ACI leafs 401/402, access policies (including the `10G-ROUTED` policy group used by node 403), AAEPs, VLAN pools, domains | `aci/` |
| ACI tenant DEV | **DELETED** — DEV content ported into PROD |
| ACI tenant UAT | **DELETED** — UAT content ported into SVCS |
| ACI tenants PROD + SVCS (VRF, BDs with `public:true` subnets and L3Out association, app profile, EPGs with `physical_domains` + `static_ports` + contract bindings) | `aci/` |
| ACI L3Outs `L3OUT-SDWAN-PROD`, `L3OUT-SDWAN-SVCS` (full: node profile, interface, BGP peer, external EPG) | `aci/` |
| Contracts `CT-PROD-PERMIT-ANY`, `CT-SVCS-PERMIT-ANY` | `aci/` |
| ACI border leaf node 403 (node registration + `eth1/1` policy group binding) | `multi-domain/aci/` |

> **ACI soft-reference behavior (Option B):** `aci/`'s L3Outs declare node 403 + `eth1/1` paths before that node is registered. ACI tolerates these as soft references — the `l3extRsNodeL3OutAtt` and `l3extRsPathL3OutAtt` relations are created in an "unformed" state and APIC raises faults until the multi-domain layer registers node 403 and binds `eth1/1` to `10G-ROUTED`. No apply-time failure; only a cosmetic fault during the gap. Once multi-domain has applied, the relations resolve automatically and BGP comes up. **Each logical object lives in exactly one repo.**
| SD-WAN base feature templates (system, AAA, banner, BFD, global, logging, NTP, OMP, security, SNMP, CLI base) | `sdwan/` |
| SD-WAN VPN definitions (VPN 0 overlay, VPN 512 mgmt, VPN 30 CORP, VPN 40 GUEST) | `sdwan/` |
| SD-WAN VPN 0 TLOC ethernet templates (TLOC1 INET, TLOC2 MPLS) | `sdwan/` |
| SD-WAN OMP `protocol: bgp` redistribution on VPN30/40 | `sdwan/` (configured on the VPN templates so BGP routes traverse the overlay) |
| SD-WAN device templates (any) | `multi-domain/sdwan/` (foundation library has none) |
| SD-WAN cEdge-01 (Site 2, device + device-template binding) | `multi-domain/sdwan/` |
| SD-WAN cEdge-02 (Site 3, device + device-template binding) | `multi-domain/sdwan/` |
| SD-WAN handoff feature templates (BGP per-VPN, dot1q sub-interface per-VPN) | `multi-domain/sdwan/` |
| SD-WAN hub device template `DT-HUB-C8000V-MULTIDOMAIN` | `multi-domain/sdwan/` |
| CATC site hierarchy (Global/USA/Nevada/Las Vegas + Bld A + floors) | `catc/` |
| CATC IP pools (CampusVN-IPPool, GuestVN-IPPool) | `catc/` |
| CATC VNs Campus + Guest (BYOD and Printers removed) | `catc/` |
| CATC anycast gateways for Campus + Guest | `catc/` |
| CATC EDGE-01, EDGE-02 (edge nodes only) | `catc/` |
| CATC BR10 (border node, full device entry) | `multi-domain/catc/` (moved — see Conflict B1) |
| CATC fabric transits + BR10 L3 handoffs | `multi-domain/catc/` |

---

## 6. Surgical Changes Per Repo

### 6.1 `aci/` — domain repo (full tenant scope under Option B)

1. **Rename `data/tenant_DEV.nac.yaml` → `data/tenant_PROD.nac.yaml`**, replace `DEV` → `PROD` everywhere. BD subnets renumbered to `192.168.10.1/24` … `192.168.15.1/24` for BD_VLAN30..35, each with `public: true`, `unicast_routing: true`, and `l3outs: [L3OUT-SDWAN-PROD]`.
2. **Rename `data/tenant_UAT.nac.yaml` → `data/tenant_SVCS.nac.yaml`**, replace `UAT` → `SVCS`. BD subnets renumbered to `192.168.20.1/24` … `192.168.25.1/24` for BD_VLAN40..45, `l3outs: [L3OUT-SDWAN-SVCS]`.
3. **Add to both tenants:**
   - **Contract** `CT-{tenant}-PERMIT-ANY` (scope: context, subjects: filter `default` permit) — wide-open lab policy.
   - **L3Out** `L3OUT-SDWAN-{tenant}` — VRF reference, `domain: ROUTED1`, `bgp: {}`, import/export route-control enforcement, node profile with `node_id: 403`, `router_id: 10.255.100.3`, interface on `port: 1` with `vlan: 3010` (PROD) / `vlan: 3020` (SVCS), IP `10.100.{10|20}.1/30`, BGP peer `10.100.{10|20}.2` `remote_as: 65200` `local_as: 65100`.
   - **External EPG** `EXT-EPG-{tenant}` with `0.0.0.0/0` (aggregate import/export route-control + import_security), consuming/providing the tenant contract.
   - **EPG contract bindings** on every internal EPG (EPG_VLAN30..35 / EPG_VLAN40..45) — consume + provide the tenant contract.
4. **Add `10G-ROUTED` leaf interface policy group** to `data/access_policies.nac.yaml` (type: access, 10G link policy, CDP/LLDP enabled, BPDU-FILTER, MCP disabled, AAEP1). Used by node 403's eth1/1 binding declared in multi-domain.
5. **Apply-time behavior standalone:** All tenant objects come up, but the L3Out node profile and interface path are soft references to node 403 / eth1/1 — they sit unformed until `multi-domain/aci/` registers the node. APIC raises a fault, no apply failure.

### 6.2 `sdwan/` — domain repo (foundation library)

1. **Delete `sdwan/data/sites.nac.yaml`.** No devices live in the foundation library. cEdge-01 and cEdge-02 are owned by `multi-domain/sdwan/`.
2. **Delete `sdwan/data/edge_device_templates.nac.yaml`.** The old `DT-USPS-SAC-REMOTE-C8000V-01` had no devices using it after Site 2 moved to multi-domain. The multidomain hub template `DT-HUB-C8000V-MULTIDOMAIN` lives in `multi-domain/sdwan/`.
3. **Remove from `sdwan/data/edge_feature_templates.nac.yaml`:**
   - `FT-ETH3-VPN30` and `FT-ETH4-VPN40` (full-interface LAN templates — superseded by the dot1q sub-interface templates in multi-domain).
   - Replace the CLI BGP block `FT-REMOTE-EDGE-CLI-BGP-BFD-01` with `FT-REMOTE-EDGE-CLI-BASE-01` (system/console only). BGP is now a proper `bgp_template` in multi-domain/sdwan/.
4. **Keep in `sdwan/data/edge_feature_templates.nac.yaml`:**
   - Base templates (AAA, banner, BFD, CLI base, global, logging, NTP, OMP, security, SNMP, system).
   - VPN definitions: `FT-REMOTE-VPN0-OVERLAY`, `FT-REMOTE-VPN512-MGMT`, `FT-REMOTE-VPN30-CORP`, `FT-REMOTE-VPN40-GUEST`. Multi-domain references VPN30/40 by name when composing the hub device template.
   - TLOC ethernet templates: `FT-TLOC1-PUBLIC-REMOTE-VPN0`, `FT-TLOC2-PRIVATE-REMOTE-VPN0`.
5. **Add `- protocol: bgp` to `omp_advertise_ipv4_routes`** on both `FT-REMOTE-VPN30-CORP` and `FT-REMOTE-VPN40-GUEST`. Without this, ACI BD subnets learned via the cEdge-01 EBGP session never enter OMP, so they never traverse the SD-WAN overlay to cEdge-02, so CATC never learns them. (Same in reverse.) The EBGP sessions would Establish but end-to-end routing would silently fail.
6. **Result:** `sdwan/` is a feature template library only — no device templates, no sites. Standalone aci/ Module 2 demo just pushes templates to vManage. `multi-domain/sdwan/` adds the hub device template + handoff-specific feature templates (BGP, dot1q sub-int) + sites on top.

### 6.3 `catc/` — domain repo

1. **Relocate site hierarchy** to `Global/USA/Nevada/Las Vegas` (host venue for Cisco Live US 2026). `catc/data/sites.nac.yaml` declares Global → USA → Nevada → Las Vegas areas, with `Bld A` (lat 36.1699, lon -115.1398, country United States) under Las Vegas and `FLOOR_1`/`FLOOR_2` under Bld A. Network settings + IP pool reservations live on Las Vegas.
2. **Remove BR10** from `catc/data/devices.nac.yaml`. EDGE-01 and EDGE-02 remain with `fabric_roles: [EDGE_NODE]` and `site: Global/USA/Nevada/Las Vegas/Bld A`.
3. **Remove `fabric_transits`** and **`border_devices`** from `catc/data/fabric.nac.yaml`. These move to `multi-domain/catc/`.
4. **Remove BYOD + Printers VNs** from `catc/data/fabric.nac.yaml` (`l3_virtual_networks`, fabric_site VN list, anycast_gateways) and the corresponding IP pool reservations from `catc/data/network_settings.nac.yaml` + `catc/data/sites.nac.yaml`. Only Campus + Guest remain — these are the two VNs handed off into the SDWAN.
5. **Keep:** Campus + Guest VN definitions, CampusVN-IPPool (192.168.100.0/24) + GuestVN-IPPool (192.168.101.0/24), anycast gateways for both VNs, EDGE-01 + EDGE-02 inventory.

### 6.4 `multi-domain/aci/` — new (border leaf only)

Under Option B, this repo owns exactly **one** thing: the border leaf node 403 and its `eth1/1` interface policy binding. Everything else on the ACI side — full PROD/SVCS tenants, L3Outs, external EPGs, contracts — is owned by `aci/`. The `terraform-provider-aci` instance here has `manage_tenants = false`; only `manage_node_policies` and `manage_interface_policies` are true.

Why this works: `aci/`'s L3Outs reference node 403 and `eth1/1` as soft references. ACI relationship objects (`l3extRsNodeL3OutAtt`, `l3extRsPathL3OutAtt`, `fvRsBDToOut`) accept dangling target DNs without rejecting the config — APIC raises faults until targets resolve. When `multi-domain/aci/` registers node 403 and binds `eth1/1` to `10G-ROUTED`, all soft references resolve and BGP comes up.

**`data/node_403_border.nac.yaml`** — the only data file in this repo:

```yaml
apic:
  node_policies:
    nodes:
      - id: 403
        pod: 1
        role: leaf
        serial_number: TEP-1-403
        name: LEAF403
        oob_address: 10.51.77.96/24
        oob_gateway: 10.51.77.254
        update_group: MG1
        access_policy_group: ALL_LEAFS

  interface_policies:
    nodes:
      - id: 403
        interfaces:
          - port: 1
            description: HANDOFF to cEdge-01 Gi3 (SD-WAN, trunk for PROD VLAN 3010 and SVCS VLAN 3020)
            policy_group: 10G-ROUTED
```

ACI has no special "border leaf" device type — any leaf hosting an L3Out is logically a border leaf. Node 403 is a standalone (no VPC group) leaf with its eth1/1 bound to the `10G-ROUTED` policy group declared in `aci/data/access_policies.nac.yaml`. VLANs 3010 and 3020 come from the existing `ROUTED1` VLAN pool (3000–3099).

**Why no `sub_port` on the L3Out interfaces:** in ACI, `sub_port` (range 1–16) is the break-out port specifier (eth1/1/1..4 when a 40G port is split into 4×10G), NOT a dot1q sub-interface. The dot1q encap on a routed sub-interface is carried by the `vlan` field alone. Two L3Outs (PROD and SVCS, declared in `aci/`) on the same physical port (eth1/1) with different `vlan` values give two separate routed sub-interfaces — no `sub_port` needed.

### 6.5 `multi-domain/sdwan/` — new

**`data/sites.nac.yaml`** — declare both cEdges:

```yaml
sdwan:
  sites:
    - id: 2
      routers:
        - hostname: SD-SITE2-C8KV-01     # cEdge-01 (HUB), moved from sdwan/
          model: C8000V
          chassis_id: C8K-D4CE7174-5261-7E6F-91EA-4926BCF4C2DD
          device_template: DT-HUB-C8000V-MULTIDOMAIN
          device_variables:
            # ACI handoff variables
            handoff_aci_eth_if_name: GigabitEthernet3
            vpn30_subif_vlan: 3010
            vpn30_subif_ipv4: 10.100.10.2/30
            vpn30_bgp_peer: 10.100.10.1
            vpn30_bgp_remote_as: 65100
            vpn40_subif_vlan: 3020
            vpn40_subif_ipv4: 10.100.20.2/30
            vpn40_bgp_peer: 10.100.20.1
            vpn40_bgp_remote_as: 65100
    - id: 3
      routers:
        - hostname: SD-SITE3-C8KV-01     # cEdge-02 (spoke, CATC-facing)
          model: C8000V
          chassis_id: <to-be-assigned>
          device_template: DT-HUB-C8000V-MULTIDOMAIN  # same template — clone if interface counts differ
          device_variables:
            handoff_catc_eth_if_name: GigabitEthernet3
            vpn30_subif_vlan: 3030
            vpn30_subif_ipv4: 10.100.30.2/30
            vpn30_bgp_peer: 10.100.30.1
            vpn30_bgp_remote_as: 65001
            vpn40_subif_vlan: 3040
            vpn40_subif_ipv4: 10.100.40.2/30
            vpn40_bgp_peer: 10.100.40.1
            vpn40_bgp_remote_as: 65001
```

**`data/edge_device_templates.nac.yaml`** — one device template, `DT-HUB-C8000V-MULTIDOMAIN`, composed by reference of:
- `FT-REMOTE-VPN0-OVERLAY` (from `sdwan/`)
- `FT-REMOTE-VPN512-MGMT` (from `sdwan/`)
- `FT-REMOTE-VPN30-CORP` (from `sdwan/`) — VPN definition; multi-domain adds the handoff attachments
- `FT-REMOTE-VPN40-GUEST` (from `sdwan/`)
- `FT-ETH3-SUBIF-VPN30` (new, multidomain)
- `FT-ETH3-SUBIF-VPN40` (new, multidomain)
- `FT-BGP-VPN30` (new, multidomain)
- `FT-BGP-VPN40` (new, multidomain)

Each service VPN's `vpn_service_templates` entry binds the sub-interface and BGP templates under it. Schema: [sdwan/schemas/schema.yaml:2606](sdwan/schemas/schema.yaml#L2606).

**`data/edge_feature_templates.nac.yaml`** — multidomain-specific feature templates ONLY (VPN30/40 templates stay in `sdwan/`):
- `FT-ETH3-SUBIF-VPN30` — Gi3.<vlan> sub-interface, dot1q encap (device_variables drive VLAN, IP, description)
- `FT-ETH3-SUBIF-VPN40` — Gi3.<vlan> sub-interface
- `FT-BGP-VPN30` — BGP AS 65200, neighbor uses device_variable for peer + remote-as
- `FT-BGP-VPN40` — BGP AS 65200, neighbor uses device_variable for peer + remote-as

All built against [sdwan/schemas/schema.yaml](sdwan/schemas/schema.yaml) constructs (`edge_feature_templates_bgp` at line 181, `edge_feature_templates_ethernet_interface` at line 464).

### 6.6 `multi-domain/catc/` — new

**`data/transit.nac.yaml`**

```yaml
catalyst_center:
  fabric:
    transits:
      - name: BGP-SDWAN
        type: IP_BASED_TRANSIT
        routing_protocol_name: BGP
        autonomous_system_number: 65200
```

**`data/border_BR10.nac.yaml`**

```yaml
catalyst_center:
  inventory:
    devices:
      - hostname: BR10
        site: Global/Poland/Krakow/Bld A
        fabric_role:
          - BORDER_NODE
          - CONTROL_PLANE_NODE
        # ... (full device entry moved from catc/)
  fabric:
    fabric_sites:
      - name: Global/Poland/Krakow
        border_devices:
          - name: BR10
            border_types: [LAYER_3]
            local_autonomous_system_number: 65001
            default_exit: true
            import_external_routes: false
            l3_handoffs:
              - name: BGP-SDWAN
                interfaces:
                  - name: GigabitEthernet1/0/3
                    virtual_networks:
                      - name: Campus
                        vlan: 3030
                        local_ip_address: 10.100.30.1/30
                        peer_ip_address: 10.100.30.2/30
                      - name: Guest
                        vlan: 3040
                        local_ip_address: 10.100.40.1/30
                        peer_ip_address: 10.100.40.2/30
```

---

## 7. CI/CD Orchestration

### 7.1 `multi-domain/.gitlab-ci.yml` — top-level orchestrator

```yaml
stages:
  - deploy-aci
  - deploy-catc
  - deploy-sdwan

deploy_aci:
  stage: deploy-aci
  trigger:
    include: aci/.gitlab-ci.yml
    strategy: depend
  rules:
    - if: '$CI_COMMIT_BRANCH == "master"'
      when: always

deploy_catc:
  stage: deploy-catc
  trigger:
    include: catc/.gitlab-ci.yml
    strategy: depend
  rules:
    - if: '$CI_COMMIT_BRANCH == "master"'
      when: always

deploy_sdwan:
  stage: deploy-sdwan
  trigger:
    include: sdwan/.gitlab-ci.yml
    strategy: depend
  rules:
    - if: '$CI_COMMIT_BRANCH == "master"'
      when: always
```

Apply order is **ACI → CATC → SD-WAN**. Rationale: SD-WAN sits in the middle of the stitching and is the only side with two EBGP sessions to bring up; deploying it last means both peers are already programmed and all four EBGP sessions converge in the final stage.

### 7.2 Per-domain `multi-domain/<d>/.gitlab-ci.yml`

Each looks like a standard NaC pipeline:

```yaml
stages: [validate, plan, apply]

validate:
  stage: validate
  script:
    - yamllint data/
    - python scripts/validate_schema.py

plan:
  stage: plan
  script:
    - terraform init
    - terraform plan -out=tfplan

apply:
  stage: apply
  script:
    - terraform apply tfplan
  when: manual    # gate apply on manual approval for the lab
```

---

## 8. Lab Guide Positioning

Five modules, each independently runnable:

| Module | Repo | What attendee sees |
|---|---|---|
| 1 | `aci/` | NaC-driven ACI fabric with leafs 401/402 and tenants PROD/SVCS |
| 2 | `sdwan/` | Library of base SD-WAN feature templates (no devices) |
| 3 | `catc/` | NaC-driven SDA fabric with EDGE-01, EDGE-02, VNs Campus + Guest |
| 4 | `ise/` | NaC-driven ISE (out of scope for this plan) |
| 5 | `multi-domain/` | **Capstone:** layers border leaf + L3Outs + 2 cEdges + service VPNs + SDA transit + BR10 handoff on top of Modules 1–3. Four EBGP sessions converge. End-to-end Campus → PROD ping demonstrates the stitched fabric. |

Module 5 ships its own `plan.md` (this file) so attendees can read the design before applying.

---

## 9. Validation Plan

After Module 5 applies:

1. **APIC**: L3Out `L3OUT-SDWAN-PROD` and `L3OUT-SDWAN-SVCS` show `BGP up`, peer 10.100.10.2 / 10.100.20.2 established. Route table on PROD VRF learns 192.168.100.0/24 (Campus); SVCS VRF learns 192.168.101.0/24 (Guest).
2. **vManage**: cEdge-01 and cEdge-02 both online, two BGP neighbors each (one fabric-side, one DC-side), all in `Established` state. OMP advertising Campus/Guest/PROD/SVCS routes.
3. **CATC**: Fabric site shows BR10 with two L3 handoffs in `Success` state; BR10 BGP table shows neighbor 10.100.30.2 and 10.100.40.2 up, learning ACI BD subnets.
4. **End-to-end**:
   - Campus client (192.168.100.x) → PROD endpoint (192.168.10–15.x) — ping works
   - Guest client (192.168.101.x) → SVCS endpoint (192.168.20–25.x) — ping works
   - Campus → Guest must FAIL (segmentation intact, VPNs not stitched together)
   - Campus → SVCS must FAIL
   - Guest → PROD must FAIL

---

## 10. Open Implementation Notes

1. **ACI soft-reference confirmation:** First run of `aci/` will create the L3Outs with dangling references to node 403 and `eth1/1`. Verify APIC raises a `topology/pod-1/node-403`-related fault on `l3extRsNodeL3OutAtt` (and corresponding faults on `l3extRsPathL3OutAtt`) rather than failing the apply. If APIC rejects the configuration on either provider, we fall back to declaring the L3Out interface block inside `multi-domain/aci/data/` while keeping the L3Out parent object in `aci/`. Initial Terraform plan should be inspected to confirm no validation errors.
2. **vManage device template uniqueness:** A device can bind to only one device template at a time. cEdge-01 fully moves to `multi-domain/sdwan/` for this reason. If you want cEdge-01 to ALSO appear in a standalone `sdwan/` demo, that demo would need to use a different chassis ID.
3. **CATC partial border:** Confirm the CATC NaC tool accepts BR10 being introduced fresh (rather than imported) in `multi-domain/catc/`. If BR10 has already been provisioned during a prior lab run, a one-time import step may be required.
4. **cEdge-02 chassis ID:** Placeholder in this plan; assign from the lab pod allocation before apply.
5. **Border leaf 403 — physical pod assignment:** Confirm node ID 403 is free in the lab pod and that the physical leaf is racked and discoverable. Plan assumes it is.
6. **Wide-open route policy:** No route-maps, no contract filtering between external and internal EPGs beyond a single permit-any. This is intentional for lab clarity; production would tighten this significantly.

---

## 11. Deliverables Checklist (after approval)

- [ ] Surgical edits in `aci/` (rename DEV→PROD, UAT→SVCS, add VRF BGP context)
- [ ] Surgical edits in `sdwan/` (remove cEdge-01 site, remove VPN30/40 feature templates, remove CLI BGP)
- [ ] Surgical edits in `catc/` (remove BR10, remove transit)
- [ ] Build `multi-domain/aci/` (node 403, two L3Outs, external EPGs)
- [ ] Build `multi-domain/sdwan/` (sites cEdge-01/-02, device template, feature templates for BGP + sub-int + VPN30/40)
- [ ] Build `multi-domain/catc/` (transit, BR10 with L3 handoffs)
- [ ] Build `multi-domain/.gitlab-ci.yml` orchestrator
- [ ] `git init` in `multi-domain/` and first commit
- [ ] End-to-end EBGP convergence validation per §9
