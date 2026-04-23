# Modeling-Heterogeneous-NPC-Behavior-through-Neurochemical-Dynamics-Personality-Traits-and-Cultural
Description: Computational architecture for autonomous NPCs integrating psychobiological drives, neurochemical dynamics (DA, NA, 5-HT), and DNA-based modulation (OCEAN &amp; Hofstede) for heterogeneous behavior.

This repository contains the source code and experimental results for a unified computational model designed to generate realistic and diverse Non-Player Character (NPC) behaviors. The project integrates psychobiological needs, neurochemical dynamics (Dopamine, Serotonin, and Noradrenaline), personality traits, and culture to create context-aware autonomous agents.

## Overview

Unlike traditional rule-based systems, this model focuses on **Behavioral Heterogeneity**. It simulates how internal biological states and external stimuli interact to produce emotional responses, grounded in the **Lövheim Cube** and **Plutchik’s** emotional categories.

### Key Features
- **Neurochemical Simulation:** Real-time tracking of Dopamine, Serotonin, and Noradrenaline levels.
- **Psychological Grounding:** Integration of Big Five personality traits (OCEAN) and Cultural Dimensions.
- **Dynamic Drive System:** NPCs react to internal needs (hunger, rest, social, safety) and environmental stimuli.
- **Godot Engine Integration:** Developed using GDScript within the Godot 4.6 ecosystem for high-performance simulation.

## Project Structure

- `/src`: The core simulation logic.
  - `scripts/npc.gd`: The main controller for NPC logic, handling real-time neurochemical updates and drive-based decision-making.
  - `scripts/simulation_world.gd`: Manages the stochastic environment, circadian cycles (day/night), and temporal scaling.
  - `scripts/stimulus_zone.gd`: Handles environmental stressors and rewards, translating context into specific neurochemical modulation factors.
  - `scripts/GlobalSettings.gd`: Configuration for simulation parameters, population generation, and global constants.
  - `scripts/DataCollector.gd`: Utility for exporting high-frequency simulation logs to CSV for statistical analysis.
  - `scenes/`: Godot scenes including the simulation world and NPC instances.
- `/results`: CSV logs and visual representations (PNGs) of NPC evolution.
  - `TOTAL_LOG_HYBRID_v15.csv`: Raw high-frequency simulation data.
  - `STATISTICAL_ANALYSIS_v15.csv`: Processed inter-agent variability and trajectory metrics.
- `Paper_Falcão_SBGames2026.pdf`: Technical paper detailing the methodology and theoretical background.

## Methodology

The system follows a multi-layered architecture:
1.  **Neurochemical Layer:** Drives the basic "mood" or state of the agent.
2.  **Affective Layer:** Maps neurochemical concentrations to specific emotions using the Lövheim Cube and Plutchik's Wheel of Emotions.
3.  **Personality and Culture Layer:** Modulates how quickly neurochemicals fluctuate and how the NPC prioritizes certain actions.
4.  **Action Layer:** Selects behaviors (e.g., seeking food, socializing, or resting) based on the highest internal drive.

## Analysis

The `/results` folder contains detailed datasets of various simulation runs. These logs track:
- **NTs (Neurotransmitters):** Temporal evolution of Serotonin, Dopamine, and Noradrenaline.
- **Needs:** Decay and fulfillment rates of psychobiological drives.
- **Emotions:** Frequency and intensity of emotional states triggered during the simulation.

## Statistical Analysis (v15 Results)

The model was validated against the drive-reduction baseline [Bicalho et al. 2025] over 1,200 simulation steps:
- **Trajectory Divergence:** High instantaneous divergence ($D \approx 0.337$) even among similar agents due to stochasticity, while maintaining biological profile consistency ($D_{avg} \approx 0.085$).
- **Emotional Reach:** 42% expansion in state-space occupancy, significantly reducing emotional stagnation.
- **Behavioral Consistency:** 33% increase in state persistence via **Neurochemical Hysteresis**, eliminating rapid state flickering.

## Tech Stack
- **Engine:** Godot Engine 4.6
- **Language:** GDScript
- **Data Analysis:** CSV logs, Matplotlib (for external visualization)

## License
This project is licensed under the terms provided in the `LICENSE` file.

---
*Developed as part of academic research at PUC-Rio (Pontifícia Universidade Católica do Rio de Janeiro).*
