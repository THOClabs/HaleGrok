/**
 * Physical constants from Hale, F.J. (1994). Introduction to Space Flight.
 * Prentice Hall. Appendix B. Ported from Hale_Orbital.Constants (Ada).
 * Units: km, s, kg, km^3/s^2.
 */
export const PI = Math.PI;
export const TWO_PI = 2 * PI;
export const HALF_PI = PI / 2;
export const DEG_TO_RAD = PI / 180;
export const RAD_TO_DEG = 180 / PI;

export const G_UNIVERSAL = 6.6743e-11;
export const C_LIGHT = 299_792.458;

export const MU_SUN = 1.32712440018e11;
export const R_SUN = 696_000.0;
export const M_SUN = 1.9885e30;
export const AU = 149_597_870.7;

export const MU_EARTH = 398_600.4418;
export const R_EARTH = 6_378.137;
export const R_EARTH_POLAR = 6_356.752;
export const M_EARTH = 5.9724e24;
export const J2_EARTH = 1.08263e-3;
export const OMEGA_EARTH = 7.292115e-5;
export const SIDEREAL_DAY_EARTH = 86_164.0905;
export const R_GEO = 42_164.0;

export const MU_MOON = 4_902.8;
export const R_MOON = 1_737.4;
export const M_MOON = 7.346e22;
export const A_MOON = 384_400.0;
export const T_MOON = 2_360_591.5;

export const MU_MARS = 42_828.37;
export const R_MARS = 3_396.2;
export const M_MARS = 6.4171e23;
export const A_MARS = 227_939_200.0;

export const MU_VENUS = 324_859.0;
export const R_VENUS = 6_051.8;
export const A_VENUS = 108_208_000.0;

export const MU_JUPITER = 126_686_534.0;
export const R_JUPITER = 71_492.0;
export const A_JUPITER = 778_570_000.0;

export const LEO_MIN_ALTITUDE = 160.0;
export const LEO_MAX_ALTITUDE = 2_000.0;
export const ISS_ALTITUDE = 420.0;
export const R_GPS = 26_560.0;

export const MU_EARTH_MOON = 0.01215058560962404;
export const MU_SUN_EARTH = 3.00273e-6;
export const MU_SUN_JUPITER = 9.537e-4;
export const MU_ROUTH_CRITICAL = 0.0385208965;

export const DEFAULT_TOLERANCE = 1e-12;
export const DEFAULT_MAX_ITERATIONS = 50;
export const CIRCULAR_THRESHOLD = 1e-10;
export const PARABOLIC_THRESHOLD = 1e-10;
export const SMALL_THRESHOLD = 1e-15;
