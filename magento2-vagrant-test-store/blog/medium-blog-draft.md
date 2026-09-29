<!--
  MEDIUM PUBLISHING NOTES (this block won't render)
  - Title:    How I Set Up a Magento 2.4.9 Test Store on a Kali Linux Vagrant Box
  - Subtitle: Sample data, mock payments, and every error I hit along the way
  - Images:   all files live in ../screenshots/ — upload them to Medium in the order they appear
  - Suggested tags: Magento, PHP, Vagrant, DevOps, Tutorial
  - Code blocks: paste as-is (Medium keeps formatting)
-->

# How I Set Up a Magento 2.4.9 Test Store on a Kali Linux Vagrant Box

*Sample data, mock payments, and every error I hit along the way.*

![Storefront](../screenshots/01-storefront-home.png)
*The finished storefront — Luma theme, 2,040 sample products, running at localhost:8080.*

---

I needed a disposable Magento test store: real catalog, real checkout, a payment method that **doesn't touch real money**, and nothing installed by clicking through wizards. The machine I had was a Windows host running a **Kali Linux Vagrant box** (originally booted for other experiments) — so instead of fighting it, I made the whole thing scripted and reproducible.

This is the walkthrough: what I built, what broke, and how it got fixed. The full runbook lives in [this GitHub repo](https://github.com/vramanufidato/OpensourcePOC/tree/main/magento2-vagrant-test-store).

## The plan

1. Boot the Vagrant box, wire up port forwarding
2. Install the stack: PHP extensions, Composer, MariaDB, Elasticsearch, Apache
3. Install Magento 2 with Composer
4. Load sample data (products, categories, customers)
5. Configure a **mock payment method**
6. Prove it works with a real end-to-end checkout — and check the order in the admin

## Choosing the stack — and the first substitution

The box already ran **Kali Linux rolling** (not Ubuntu — package names differ: Kali ships unversioned `php-*` packages for its PHP 8.4). RAM was 3.8 GB and disk had 55 GB free — enough for Magento, which officially wants 2 GB+.

Then came decision #1. Magento's official Composer repo, `repo.magento.com`, requires **Adobe Marketplace access keys** — mine returned a clean `HTTP 401`. I didn't have keys handy, and for a throwaway test store I didn't want to create any. Enter **Mage-OS**: a community distribution of Magento Open Source that is drop-in compatible and publishable through a **key-free mirror** at `repo.mage-os.org`. Same codebase lineage, no credentials. Mage-OS 3.5.0 is based on **Magento 2.4.9** — done deal.

## Step 1 — The box and its ports

Magento needs three openings: the web server, MySQL, and (guest-internal) Elasticsearch. My first `Vagrantfile` edit looked innocent:

```ruby
config.vm.network "forwarded_port", guest: 80,   host: 8080, host_ip: "127.0.0.1", auto_correct: true
config.vm.network "forwarded_port", guest: 3306, host: 3306, host_ip: "127.0.0.1", auto_correct: true
```

Except… an earlier experiment already claimed **host port 8080** (a little Node.js booking app). Two forwards, one port — no. The booking app moved to 8081, Magento took 8080, and `auto_correct: true` now guards against future collisions:

![Vagrant port forwarding](../screenshots/09-terminal-vagrant-ports.png)
*`vagrant up` wiring guest ports to the host. 80 → 8080 and 3306 → 3306 are the new tenants.*

## Step 2 — Dependencies (and an Elasticsearch ambush)

Inside the box:

```bash
sudo apt-get update
sudo apt-get install -y composer php-bcmath php-curl php-gd php-intl php-mbstring \
  php-mysql php-soap php-xml php-zip libapache2-mod-php
```

Kali already carried MariaDB and Apache binaries, so the database was a `systemctl enable --now` away. MariaDB is MySQL's drop-in replacement on Debian-family distros — `CREATE DATABASE magento;` and a dedicated user, exactly what `bin/magento` expects.

**Elasticsearch was the ambush.** Magento 2.4+ requires it, so I added Elastic's official 8.x apt repo and installed it. Two separate failures followed:

1. The 8.x deb package **auto-configures security** (TLS + passwords) by appending multi-line `xpack.*` blocks to `elasticsearch.yml`. My sed-based edit commented out the top-level lines but left orphaned indented children — YAML dead on arrival: `expected <block end>, but found '<block mapping start>'`. A clean, minimal config file solved that:

```yaml
network.host: 127.0.0.1
discovery.type: single-node
xpack.security.enabled: false
xpack.ml.enabled: false
```

2. Then ES still refused to boot: `invalid configuration for xpack.security.transport.ssl` — the auto-generated **keystore** still held `secure_password` entries for TLS that no longer existed. Deleting those three keystore entries finally let the node start.

The takeaway: disabling security on an auto-configured ES 8 node is a *two-step* operation — config **and** keystore.

## Step 3 — Installing Magento

With the stack ready:

```bash
composer create-project --no-interaction \
  --repository-url=https://repo.mage-os.org/ \
  mage-os/project-community-edition magento2
```

Gotcha #2: the mirror publishes the project under the **`mage-os/`** namespace — `magento/project-community-edition` simply isn't there.

Gotcha #3 arrived at install time: `The "--admin-username" option does not exist`. Magento 2.4.9 renamed the flag to `--admin-user`. The final command:

```bash
php bin/magento setup:install -n \
  --base-url=http://localhost:8080/ \
  --db-host=127.0.0.1 --db-name=magento \
  --db-user=magento_user --db-password=magento_password \
  --admin-firstname=Admin --admin-lastname=User \
  --admin-email=admin@example.com \
  --admin-user=admin --admin-password='Admin123!' \
  --language=en_US --currency=USD --timezone=UTC \
  --use-rewrites=1 --backend-frontname=admin \
  --search-engine=elasticsearch8 \
  --elasticsearch-host=127.0.0.1 --elasticsearch-port=9200
```

![Install success](../screenshots/05-terminal-install-success.png)
*1,348 steps later: "Magento installation complete."*

## Step 4 — Sample data

One command chain: `sampledata:deploy` (Composer pulls the sample-data modules), `setup:upgrade` (imports products, categories, customers), `setup:di:compile`, `setup:static-content:deploy en_US`, `indexer:reindex`, `cache:flush`.

![Sample data pipeline](../screenshots/06-terminal-sampledata-pipeline.png)
*Upgrade complete, DI compiled, static content 100%, all 11 indexers green — 2,040 products ready.*

One subtlety: the classic `magento/sample-data` metapackage doesn't exist on the Mage-OS mirror, but Mage-OS ships its own `mage-os/module-*-sample-data` packages, and `sampledata:deploy` discovers them automatically through Composer `suggest` entries. It just worked.

## Step 5 — Mock payment

The requirement: test orders **without real payment processing**. Magento's built-in **Check / Money Order** method is exactly that — no gateway, no card capture:

```bash
php bin/magento config:set payment/checkmo/active 1
php bin/magento config:set carriers/flatrate/active 1   # a shipping method for checkout
```

(The famous `4111 1111 1111 1111` test card is only relevant once a *card* gateway module exists — checkmo never asks for one.)

## Step 6 — Proving it works end-to-end

The admin and storefront came up clean:

![Admin login](../screenshots/04-admin-login.png)
*The Mage-OS admin sign-in page.*

Then the fun part: a scripted guest checkout against the **real REST API** — create cart, add a Joust Duffle Bag, pick Flat Rate, choose checkmo, place the order:

![Checkout](../screenshots/07-terminal-checkout-order.png)
*`ORDER RESULT: 3` — a $39.00 order (item + $5 flat rate), status `pending`, nothing captured.*

Finally, verifying the order exists where a human would look — **Admin → Sales → Orders** (the grid reads from `sales_order_grid`):

![Admin orders data](../screenshots/08-terminal-admin-orders-data.png)
*Order `000000003`, method `checkmo`, `amount_paid` NULL — exactly what "mock payment" should mean.*

## Every error I hit (so you don't have to)

1. `repo.magento.com` → **401** without Marketplace keys → switched to the Mage-OS mirror
2. `Could not find package magento/project-community-edition` → it's `mage-os/project-community-edition` there
3. `--admin-username` doesn't exist in 2.4.9 → renamed to `--admin-user`
4. ES YAML broken by partial commenting of auto-config blocks → clean minimal config
5. ES keystore still holding TLS secrets after disabling security → remove the keystore entries
6. Admin **HTTP 500** after install → `www-data` needed group-write access (`chown` + recursive ACLs on `var/ generated/ pub/ app/etc`)
7. The VM got **aborted** by an abrupt host stop mid-run — `vagrant up` recovered everything; enabled services auto-start

## Final thoughts

The whole store is now one `vagrant up` plus a dozen numbered scripts — reproducible, disposable, and honest about its test-only credentials. Next iterations I'd consider: Redis for cache/sessions, PHP-FPM + nginx instead of mod_php, and a tiny custom payment module that renders a fake card form (so the `4111…` numbers finally have a home).

If you want the full runbook — every script, the troubleshooting table, and the screenshots — it's here:
[github.com/vramanufidato/OpensourcePOC → magento2-vagrant-test-store](https://github.com/vramanufidato/OpensourcePOC/tree/main/magento2-vagrant-test-store)

---

*Thanks for reading — claps and corrections are both welcome.* 👏

`#Magento` `#PHP` `#Vagrant` `#DevOps` `#Tutorial`
