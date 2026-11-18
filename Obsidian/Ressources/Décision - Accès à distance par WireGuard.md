---
décision: "Accès à distance par WireGuard"
date: 2026-11-19
statut: "acceptée"
# statut possible : en-réflexion | acceptée | abandonnée | remplacée
étape-liée: "Étape 08 — Accès à distance sécurisé (WireGuard)"
tags: [décision, ressources]
---

# Décision — Accès à distance par WireGuard

## Contexte
> L'application (API, base, bientôt frontend web) tourne sur un serveur du réseau local
> de mon père. Ma famille doit pouvoir l'utiliser depuis l'extérieur, sur PC Windows et
> sur mobile, avec des **données financières réelles**. Il faut donc un accès à distance
> sans exposer l'application à tout Internet, et gratuit.

## Options envisagées

### Option A — WireGuard auto-hébergé
**Avantages :**
- open source, gratuit, aucun service tiers : je maîtrise toute la chaîne
- l'application reste **invisible depuis Internet** : seul un port UDP est ouvert,
  et WireGuard ne répond à aucun paquet non authentifié
- chiffrement de bout en bout, rien ne transite en clair chez un tiers
- formateur : clés, pairs, routage, pare-feu (objectif cybersécurité)

**Inconvénients :**
- une configuration à générer et installer **par appareil** (QR code pour les mobiles)
- un port à rediriger sur la box ; impossible si le FAI utilise le CGNAT
- la famille doit activer le VPN avant d'ouvrir l'application
- ne fournit **pas** de certificat HTTPS (voir Conséquences)

### Option B — Tailscale
**Avantages :**
- basé sur WireGuard, sans aucune configuration : une appli et un compte suffisent
- certificat HTTPS fourni (`*.ts.net`), aucun port à ouvrir

**Inconvénients :**
- dépendance à un service tiers pour la coordination, limites du plan gratuit
- moins formateur : la mécanique est cachée

### Option C — Cloudflare Tunnel (+ Cloudflare Access)
**Avantages :**
- vraie adresse publique, rien à installer pour la famille, HTTPS automatique

**Inconvénients :**
- nécessite un nom de domaine (≈ 10 €/an) : pas totalement gratuit
- Cloudflare **déchiffre le trafic** : un tiers voit les données financières

### Option D — Exposition directe (redirection de port + Caddy + DuckDNS)
**Avantages :**
- gratuit, sans tiers, vraie adresse publique

**Inconvénients :**
- l'application devient attaquable depuis tout Internet, sur le réseau de mon père
- exige au préalable rate limiting, refresh tokens, surveillance des logs

## Décision retenue
> **Option A — WireGuard**, parce qu'il garde l'application hors d'Internet sans
> confier les données à un tiers, qu'il est gratuit et qu'il correspond à mon objectif
> d'apprentissage en sécurité. La contrainte d'une configuration par appareil est
> acceptable pour une poignée d'utilisateurs.

## Conséquences
> - **Un pair WireGuard par appareil** (pas par personne) : une perte de téléphone se
>   règle en supprimant ce seul pair.
> - Configurer les clients en **tunnel partiel** (`AllowedIPs` limité au réseau du
>   serveur) pour ne pas faire passer toute leur navigation par la maison.
> - **HTTPS reste à faire** (étape R7d) : le stockage sécurisé du jeton exige un contexte
>   sécurisé dans le navigateur. Piste retenue : Caddy + nom DuckDNS + certificat
>   Let's Encrypt par défi DNS, sans rien exposer.
> - Les inscriptions seront **fermées** (`REGISTRATION_OPEN=false`) une fois la famille
>   inscrite : le VPN est la première barrière, l'authentification la seconde.
> - Options B et C restent des solutions de repli si la box passe en CGNAT.

## Liens
- [[Étape 08 — Accès à distance sécurisé (WireGuard)]]
- [[WireGuard]]
- [[Décision - Architecture multi-utilisateurs]]
