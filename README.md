# 🧩 Sudoku Game in SWI-Prolog

A logic-based Sudoku game and solver built using **SWI-Prolog**, demonstrating Prolog’s **reasoning, constraint-solving**, and **backtracking** capabilities.

---

## 🎯 Objectives
- Explore logic-based problem solving using Prolog.
- Represent Sudoku puzzles through facts, rules, and constraints.
- Apply constraint logic programming (CLP(FD)) to validate Sudoku boards.
- Implement automatic puzzle generation and user interaction.
- Showcase Prolog’s intelligent reasoning for AI-based tasks.

---

## ⚙️ Features
- Automatic Sudoku puzzle generation.
- Validation using Prolog constraints (`all_distinct/1`, domain rules, etc.).
- Interactive input for users to fill missing squares.
- Backtracking-based reasoning to find correct solutions.
- Clean, rule-driven logic — no imperative control flow needed.

---

## 🧠 How It Works
- The Sudoku board is represented as a **list of lists** (a matrix).
- Constraints ensure:
  - Each row, column, and 3×3 subgrid has unique numbers.
  - Each cell contains values from 1–9.
- Prolog’s **backtracking mechanism** automatically finds valid solutions that satisfy all constraints.

---

## 📸 Demonstration
Add screenshots or short terminal output examples here, for example:

