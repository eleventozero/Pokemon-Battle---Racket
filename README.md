# 🐉 Pokemon Battle (Racket)

A functional Pokémon battle system implemented in **Racket (`#lang racket/base`)**.  
The project follows a **pure functional design**, using immutable data structures and explicit state transitions.

---

## ✨ Features

- ⚔️ Turn-based battle system (Player vs Enemy)
- 🔁 Pure functional state management (no mutation)
- 🧠 Type effectiveness system (Gen 1 inspired)
- 💾 SQLite database integration
- 🧩 Modular architecture (API, DB, Logic, UI)

---

## 🖼️ Screenshots

### Main Menu
<img width="1521" height="317" alt="menu" src="https://github.com/user-attachments/assets/ef5ad502-6912-45ed-828b-4967a207def1" />

### Battle Screen
<img width="1521" height="643" alt="battle_screen" src="https://github.com/user-attachments/assets/a98b9804-5675-46dc-bc3e-3b67d9436eaf" />

### Pokemon Selection
<img width="1521" height="643" alt="pokemon_selection" src="https://github.com/user-attachments/assets/9b786461-8b49-4567-8feb-43463a5191f0" />

---

## 📦 Data Model

### Pokemon

| Field        | Type   | Description|
|--------------|--------|------------|
| name         | String | Name       |
| current-hp   | Int    | Current HP |
| base-hp      | Int    | Max HP     |
| base-attack  | Int    | Attack     |
| base-defense | Int    | Defense    |
| type         | Symbol | e.g.'fire  |
| attacks      | Vector | 3 attacks  |

---

### Attack

| Field  | Type   | Description |
|--------|--------|-------------|
| name   | String | Attack name |
| damage | Int    | Base damage |
| type   | Symbol | e.g. 'water |

---

### State

| Field        | Description         |
|--------------|---------------------|
| player-team  | List of Pokemon     |
| enemy-team   | List of Pokemon     |
| p-active     | Player active index |
| e-active     | Enemy active index  |
| turn         | #t = player         |

---

## 📌 Future Improvements

- Status effects (poison, burn, etc.)
- Improved enemy AI (strategy instead of random)
- Extended type system (full Gen 1 mechanics)

---

## ⭐ Notes

This project is designed as a learning system to explore:

- Functional programming in Racket
- Clean architecture and separation of concerns
- Game logic implementation
- Database integration with SQLite
