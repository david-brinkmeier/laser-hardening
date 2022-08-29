# Laser Hardening / Heat Conduction Welding

![](doc/1.png?raw=true)

## Overview
- This code basically implements [eq. (6) and eq. (5)][ClineAnthony] derived by Cline and Anthony, and uses the same math to numerically adapt the solution to arbitrary heat source geometries in an efficient way.
- Please note that there are errors in eq. (6), the correct version can be found in [Conduction of Heat in Solids, p. 267][CarslawJaeger].
- Please also note that the equations are somewhat confusing when comparing the literature, because the authors use different definitions.
- The relevant equations are implemented in methods getPTKernel and getGAUSSKernel of class [heatSim](/!dependencies/classes/@heatSim/heatSim.m).
- The formulation is adapted for efficient numerical implementation.
- Re-calculations are only performed when necessary, which is tracked by using unique identifiers for the input variables of the simulation.
- Example: If material and intensity distribution is not changed, changing the laser power does not require re-calculation and a linearly scaled version of the previous temperature field can be used.
- Gaussian spread / diameter / radius is based on the ISO11146 D4σ definition for laser beams.
- You can specify custom materials.
- You can specify various pre-implemented heat source geometries as well as user defined heat sources.

## Get Started
- Simply run [main.m](main.m).
- Read [main.m](main.m) carefully and comment / un-comment code snippets for testing different heat sources as you wish.

## Limitations
- Cline-Anythony's equation is also quite successfully used in the literature for heat conduction welding, but of course there is no consideration of fluid dynamics, so keep this in mind.
- Thermophysical properties are constants in the calculation.
- Implemented analysis of the resulting temperature fields may or may not be in agreement with your theory / knowledge of heat treatment.

## Interface

- The setup is done in script [main.m](main.m).
- Interaction with the results is implemented in a rudimentary way using linked figures with some interactivity using the mouse and left/right mouse button in the XY temperature graph.

![](doc/2.png?raw=true)

- This is what a custom / user-specified intensity distribution could look like.

![](doc/3.png?raw=true)

## Disclaimer

- Code is provided "as is".

[ClineAnthony]: <https://aip.scitation.org/doi/10.1063/1.324261>
[CarslawJaeger]: <https://books.google.de/books/about/Conduction_of_Heat_in_Solids.html?id=y20sAAAAYAAJ&redir_esc=y>