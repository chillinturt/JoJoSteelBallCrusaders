# JoJo: Steel Ball Crusaders (Multiplayer Systems Project)

**Multiplayer, real-time game systems project demonstrating distributed systems, client–server architecture, and production-style software ownership**

---

## Overview

**JoJo: Steel Ball Crusaders** is a multiplayer game project built on the Roblox platform, where I designed and implemented **real-time, networked gameplay systems** with a strong focus on **reliability, state synchronization, and performance under live multiplayer conditions**.

The project is actively developed and tested in a **real-world production environment**, with live players, continuous iteration, and rapid debugging cycles based on observed runtime behavior.

This repository represents a **systems-oriented software engineering project**, not just a game.

---

## Key Technical Highlights (Relevant to Starlink)

### Real-Time, Distributed Software
- Designed **client–server gameplay architecture** with authoritative server logic
- Implemented **network-synchronized ability systems** with strict consistency guarantees
- Managed real-time **visual effects lifecycles** across multiple clients
- Ensured deterministic behavior under latency and player churn

### Reliability & State Management
- Built robust **cooldown, resource, and state validation systems** to prevent desynchronization
- Solved complex issues involving:
  - Player death and respawn
  - UI state persistence across character resets
  - Preventing invalid state transitions in live sessions
- Defensive programming to handle partial failures and unexpected client behavior

### Software Ownership & Iteration
- Responsible for the **entire software lifecycle**:
  - Design
  - Implementation
  - Debugging
  - Live testing
  - Refinement based on observed runtime behavior
- Regularly closed the feedback loop between:
  - Design assumptions
  - Actual multiplayer runtime performance

### Architecture & Code Quality
- Modular system design (ability registry, cooldown manager, VFX system)
- Clear separation of concerns between:
  - Gameplay logic
  - Networking
  - Presentation
- Designed extensible systems to support rapid prototyping of new abilities

---

## Networking & Distributed Systems Experience

While implemented within Roblox’s networking model, the project demonstrates **core distributed systems concepts** applicable beyond game development:

- Client–server message passing
- Server-authoritative validation
- Latency-aware design
- Synchronization of transient and persistent state
- Security-minded design (preventing client-side authority exploits)
- Highlight: many major **VFX do not exist on the server.** The server simply tells all clients to render them, thus saving the server's processing power.

These concepts directly translate to **large-scale distributed systems** like those used in satellite communications and real-time networked services.

---

## Collaboration & Leadership

- Led a **cross-disciplinary team** of contributors:
  - Environment builders
  - Asset researchers
  - Animators
- Defined technical constraints and interfaces so non-programmers could work independently
- Acted as **sole software engineer**, owning all programming decisions and integrations
- Practiced clear written communication through documentation and internal coordination

This mirrors real engineering environments where software engineers collaborate across disciplines.

---

## Technologies & Languages

- **Primary Languages:** Lua (Roblox)
- **Concepts:**  
  - Real-time systems  
  - Distributed state synchronization  
  - Client–server architecture  
  - Event-driven design  
  - Debugging live systems  
- **Tools:** Roblox Studio, Git/GitHub

---

## Why This Project Is Relevant to Starlink (I love Starlink!)

This project demonstrates:
- Ability to build **highly reliable, real-time software**
- Comfort working in **distributed, networked environments**
- Strong **engineering fundamentals** and problem-solving skills
- Full ownership of production software used by real users
- Willingness to iterate rapidly and handle changing requirements

While the application domain is a game, the **engineering challenges mirror those found in real-world, large-scale systems** — including networking, reliability, performance, and state management.

Some content from the game:
<img width="1903" height="999" alt="image" src="https://github.com/user-attachments/assets/969900cb-a2a9-4c7a-8da9-58515cc8097d" />

Fully playable game link (working on PC, IOS, and Android):
https://www.roblox.com/games/118168989887674/JoJo-Steel-Ball-Crusaders#!/game-instances
---

## Repository Visibility Note

This repository represents a **sanitized and shareable subset** of the full project.  
Additional details, architecture discussions, and live demonstrations can be provided upon request. (Now available on Mobile)

---

## Author

**ChillinTurt**  
Software Engineering Student (Graduating 2025–2026)  
Strong background in C++, Python, C#, Lua, and real-time distributed systems


# JoJoSteelBallCrusaders
Generated by [Rojo](https://github.com/rojo-rbx/rojo) 7.5.1.

## Getting Started
To build the place from scratch, use:

```bash
rojo build -o "JoJoSteelBallCrusaders.rbxlx"
```

Next, open `JoJoSteelBallCrusaders.rbxlx` in Roblox Studio and start the Rojo server:

```bash
rojo serve
```

For more help, check out [the Rojo documentation](https://rojo.space/docs).
