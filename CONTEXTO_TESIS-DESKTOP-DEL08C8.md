# Contexto del proyecto — Tesis / Artículo de sociología

> Documento de traspaso para continuar el trabajo en Claude Code (R + Markdown).
> Resume decisiones de diseño, datos, hallazgos preliminares y próximos pasos.

---

## 1. Objetivo y formato del producto

- **Producto:** un **artículo** (formato revista), NO una tesis larga. Escritura en **Markdown** con un formato/plantilla ya establecido.
- **Idioma:** español.
- **Análisis:** en **R**.
- **Plazo:** intensivo (menos de un mes desde mediados de junio 2026).

## 2. Tema y pregunta de investigación

Cómo influyen los **discursos meritocráticos** y las **diferencias por cohorte/generación** en la **justificación de la desigualdad** en **salud** y **educación** en Chile, usando datos ISSP "Social Inequality" (1999, 2009, 2019).

### Argumento central (tentativo)
El efecto de la adhesión a discursos meritocráticos sobre la justificación de la desigualdad en salud y educación **no es uniforme: varía según la cohorte de nacimiento**, y esa variación se transforma entre olas, sugiriendo que el contexto histórico de socialización modula la fuerza del discurso meritocrático como mecanismo de legitimación.

### Foco temporal sugerido
Comparación rica **2009 vs. 2019** (Chile pre- y post-ciclo que culmina en el estallido social de 2019), con **1999 como referencia descriptiva**. Ver "Caminos de diseño" abajo.

## 3. Decisión conceptual clave: cohortes, no generaciones difusas

Se discutió generaciones vs. cohortes vs. período vs. edad. Decisión: trabajar **cohortes** (año de nacimiento) reconociendo el problema de **identificación Edad-Período-Cohorte** (edad = período − cohorte; no se pueden separar limpiamente los tres con pocas olas). Con 3 olas no se hace un APC formal; se hace comparación de cohortes entre momentos, reconociendo la limitación.

### Cortes de cohorte (periodización chilena, NO usar "Estado de Bienestar")
- **Desarrollista**: nacidos hasta ~1958 (Estado de compromiso / ISI, previo al quiebre)
- **Dictadura**: ~1959–1973 (socialización bajo régimen militar y reformas neoliberales)
- **Transición**: ~1974–1990 (juventud en recuperación democrática)
- **Neoliberal consolidado**: ~1991+ (socialización plena en democracia de mercado)
- Posible cohorte adicional **post-2001** ("nativos del malestar"), que solo aparece bien representada en 2019.

> Nota: las cohortes jóvenes solo se pueblan en olas recientes. En 2009 los nacidos en 1991+ eran ~17 casos. En 2019 estarán bien representados. Esto debe reconocerse al interpretar interacciones cohorte × ola.

## 4. Datos

Tres archivos ISSP descargados de GESIS (todos los países; hay que filtrar Chile):

| Ola | Archivo | Var. país | Código Chile | N Chile |
|---|---|---|---|---|
| ISSP 1999 | `ZA3430_2006-09-14.sav` | `V3` | 30 ("RCH Chile") | 1503 |
| ISSP 2009 | `ZA5400_v4-0-0.sav` | `V5` | 152 ("CL-Chile") | 1505 |
| ISSP 2019 | `ZA7600_v3-0-0.sav` | `c_alphan` | "CL" (string) | 1374 |

- Los `.sav` se leen en R con `haven::read_sav()`.
- **El CEP 2009 que se usó al inicio (`Encuesta_CEP_59_May-Jun_2009.sav`, N=1505) ES el ISSP 2009 aplicado en Chile** — mismos datos, distinta presentación. Para máxima comparabilidad usar las **tres olas directamente desde ISSP**.
- **Patch `ZA5400_..._Patch_V67-V68.sps`: IGNORAR.** Solo recodifica V67/V68 (valor monetario de vivienda y ahorros). No toca ninguna variable del estudio.
- Atención a **codificación de perdidos**: 2009 usa 8/9 ("Can't choose"/"NA"); 2019 usa -8/-9. Armonizar a NA.
- Atención a **factor de expansión / ponderador** ISSP (variable de peso por país, p. ej. `WEIGHT`/`factor`) — verificar e incorporar en los modelos.

## 5. Variables (mapeo entre olas, por CONTENIDO no por nombre)

Los nombres cambian entre olas (1999: `V##` mayúscula; 2009: `V##` mayúscula; 2019: `v##` minúscula).

### Variables dependientes (en las TRES olas) — escala 1 "muy justo" a 5 "muy injusto"
| Concepto | 1999 | 2009 | 2019 |
|---|---|---|---|
| Justifica desigualdad SALUD ("rich can buy better health care") | `V39` | `V38` | `v30` |
| Justifica desigualdad EDUCACIÓN ("...better education for children") | `V40` | `V39` | `v31` |

> Las dos VD están **muy correlacionadas (r≈0.82 en 2009)**. Niveles parecidos entre sectores; lo interesante es si los **predictores** difieren por sector.
> Ojo dirección de la escala: 1=muy justo … 5=muy injusto. Para interpretar "mayor = más justifica" conviene **invertir** (recodificar 6 - x) o tenerlo claro al leer coeficientes.

### Batería "Getting ahead" (atribuciones de éxito) — SOLO 2009 y 2019
2009 = `V6..V16` (11 ítems); 2019 = `v1..v10` (10 ítems).

| Concepto | 2009 | 2019 |
|---|---|---|
| Familia rica | V6 | v1 |
| Padres educados | V7 | v2 |
| Educación propia | V8 | v3 |
| **Ambición** | V9 | — (NO está en 2019) |
| Trabajo duro | V10 | v4 |
| Conocer gente adecuada | V11 | v5 |
| Contactos políticos | V12 | v6 |
| Coimas | V13 | v7 |
| Raza | V14 | v8 |
| Religión | V15 | v9 |
| Sexo | V16 | v10 |

> **NO existe en 1999** en este formato. El 1999 trae otros ítems de meritocracia tipo acuerdo/desacuerdo (V6 "people get rewarded for their effort", V7 "...for their skills") que NO son equivalentes.

### Batería normativa "importance for pay" — comparable solo parcialmente
- Único ítem normativo presente en las TRES olas: **educación/años de formación para fijar el pago** → 1999 `V50`, 2009 `V48`, 2019 `v45`.
- La batería normativa completa que se exploró en el CEP (responsabilidad, educación, desempeño, esfuerzo) NO es idéntica entre olas (en 1999 faltan esfuerzo y desempeño).

### Cohorte / edad y controles (en las tres olas)
- **Edad**: `AGE` en las tres olas (rango Chile 1999: 18–94). Año de nacimiento ≈ año de ola − AGE.
- Controles disponibles: **sexo, escolaridad (años), ingreso, posición política (izq–der), religiosidad (asistencia)**. Ingreso y posición política tienen **alto % de NA** (~20–25%) → la N listwise cae bastante; correr modelos con y sin esos controles.

## 6. Índices construidos (decisiones validadas con análisis factorial sobre 2009)

Se hizo análisis factorial (KMO=0.78, Bartlett sig.) sobre la batería "getting ahead". **Resultado clave: mérito y estructura NO son polos opuestos de una sola dimensión** (la correlación entre factores era ~0.14, casi independiente). Por tanto NO se usa un índice bipolar; se usan índices separados.

Tres índices (todos en escala 1–5 tras invertir para que **mayor = más importante/más adhesión**):

1. **Meritocracia normativa** (batería "importance for pay" 22; en CEP: TE2P22 A,B,E,F). Alpha de Cronbach ≈ 0.71. *Comparable entre olas solo vía el ítem educación.*
2. **Meritocracia descriptiva** (getting ahead: educación propia + ambición + trabajo duro). **Para comparar 2009–2019 reconstruir SIN ambición** (educación propia + trabajo duro), porque ambición falta en 2019.
3. **Particularismo / barreras adscriptivas** (getting ahead: raza + sexo + religión + coimas + contactos políticos [+ familia rica, según factor]). **Intacto en 2009 y 2019.**

> El análisis factorial de la batería normativa "should earn / importance for pay" mostró además un segundo factor de **"necesidad"** (mantener familia, hijos). Se decidió **excluirlo del índice meritocrático** y usarlo como evidencia de **validez discriminante** (mostrar que mérito ≠ necesidad). No entra como predictor principal.

## 7. Hallazgos preliminares (SOLO ola 2009, exploratorio, sin ponderador)

> ⚠️ Todo esto es exploratorio sobre una ola. NO son resultados finales. Replicar correctamente en R con ponderador y en las olas que correspondan.

### Correlaciones bivariadas índice → VD (2009), N≈1432
- Meritocracia normativa → salud 0.014 / educación 0.020 (≈nula)
- Meritocracia descriptiva → salud 0.046 / educación 0.078 (débil)
- Particularismo → salud 0.110 / educación 0.111 (la más fuerte, y positiva)
- VD salud ↔ educación: 0.820

### Ordered logit (VD ordinal 1–5), predictores estandarizados (z), N=1419
Cohorte ref = Desarrollista (≤1958). Controles: mujer, escolaridad (z), religiosidad (z).

Predictores **significativos y consistentes en ambos sectores**:
- **Particularismo**: OR≈1.21–1.23, p<0.001 (más particularismo → MÁS justifica). *Contraintuitivo — requiere interpretación teórica.*
- **Escolaridad**: OR≈1.24–1.31, p<0.001 (más años → MÁS justifica).
- **Cohortes jóvenes** (vs. Desarrollista): Dictadura OR≈0.67–0.75 (p<0.05); Transición OR≈0.55–0.64 (p<0.001). Las cohortes jóvenes **justifican MENOS**, efecto creciente. (Apoya H de gradiente generacional.)

Predictores **NO significativos**: meritocracia normativa, meritocracia descriptiva (efecto principal), sexo, religiosidad.

Pseudo-R² muy bajo (~0.012). Reportar honestamente.

### Interacción meritocracia descriptiva × cohorte (2009)
- **SALUD: interacción SIGNIFICATIVA (p<0.05).** Efecto de meritocracia descriptiva por cohorte (coef logit): Desarrollista **−0.128** → Dictadura **+0.119** → Transición **+0.104**. **El signo se invierte entre generaciones** → apoya el argumento central.
- **EDUCACIÓN: misma dirección pero NO significativa** (p=0.43 / 0.15).
- Significancia marginal (p=0.039, 0.048): frágil. Hay asimetría sectorial (salud sí, educación no) a explicar teóricamente.

### Lectura estratégica
Dos historias compiten por protagonismo: (a) meritocracia moderada por cohorte (elegante pero frágil, solo salud, solo 2009); (b) particularismo + escolaridad (robusta, ambos sectores, pero contraintuitiva). El artículo más fuerte probablemente **integra ambas**. La prueba real es si la interacción se **replica/evoluciona** entre 2009 y 2019.

## 8. Caminos de diseño (decisión pendiente; preferencia actual = B)

- **Camino A** — longitudinal estricto 3 olas solo con lo comparable (2 VD + meritocracia normativa-educación + cohorte). Limpio pero pobre; pierde el particularismo (el mejor predictor) en 1999.
- **Camino B (preferido)** — dos niveles: (i) tendencia general 1999→2009→2019 de las VD + meritocracia normativa; (ii) análisis del mecanismo (particularismo + meritocracia descriptiva × cohorte) en **2009 y 2019** (batería rica disponible). Reconoce limitaciones honestamente.
- **Camino C** — eje central 2009 vs 2019 (datos ricos, narrativa pre/post-estallido), 1999 como referencia descriptiva.

> B y C son compatibles: el análisis del mecanismo de B es esencialmente la comparación 2009–2019 de C.

## 9. Estructura del dataset a construir (en R)

Un **único dataset integrado (pooled) de las tres olas**, formato long:
- Filtrar Chile en cada ola (ver códigos en §4).
- Renombrar variables a nombres comunes (p. ej. `just_salud`, `just_educ`, `merit_norm_educ`, ítems getting-ahead, `edad`, controles).
- Armonizar escalas y perdidos (8/9 y -8/-9 → NA).
- Crear variable `ola` (1999/2009/2019) y `cohorte` (desde `año_ola - AGE`).
- Particularismo y meritocracia descriptiva quedarán **NA en todas las filas de 1999** (es correcto: esos análisis excluyen 1999 automáticamente).
- Incorporar **ponderador** ISSP.
- Construir índices (§6): meritocracia descriptiva SIN ambición para comparabilidad 2009–2019; particularismo completo.

## 10. Próximos pasos en R (orden sugerido)

1. **Plomería de datos**: leer las 3 olas (`haven::read_sav`), filtrar Chile, renombrar/armonizar, construir `ola`, `cohorte`, perdidos, ponderador → dataset pooled (guardar como `.rds`).
2. **Verificar invarianza de la estructura factorial** de la batería getting-ahead entre 2009 y 2019 (¿los dos factores —mérito / particularismo— se repiten?). Paquetes: `psych` (EFA), o `lavaan` para CFA / invarianza de medición.
3. **Construir índices** y reportar fiabilidad (alpha) por ola.
4. **Descriptivos** por ola y cohorte (niveles de las VD, de los índices) + tabla descriptiva del artículo.
5. **Modelos**: ordered logit (`MASS::polr` o `ordinal::clm`) con ponderador (`survey::svyolr` si se usa diseño complejo) sobre cada VD:
   - Modelo base (predictores + controles + cohorte + ola)
   - Modelo con interacción **meritocracia × cohorte**
   - Modelo con interacción triple o estratificado por **ola** (¿cambia el patrón 2009→2019?)
6. **Efectos marginales / predicciones** para interpretar interacciones (`marginaleffects` o `ggeffects`), con gráficos.
7. **Robustez**: con/sin ingreso y posición política (NA altos); con/sin ponderador; VD como lineal vs ordinal.
8. **Redacción** en Markdown según plantilla, integrando tablas (`gtsummary`, `modelsummary`) y figuras.

### Paquetes R sugeridos
`haven`, `dplyr`/`tidyverse`, `psych`, `lavaan`, `MASS`, `ordinal`, `survey`, `srvyr`, `marginaleffects`, `ggeffects`, `modelsummary`, `gtsummary`, `ggplot2`. Para el documento: `rmarkdown` / `quarto`.

## 11. Cosas a no olvidar / advertencias

- Mantener SIEMPRE: primero el output/tabla cruda, después la interpretación.
- Reportar N de cada modelo y la caída por listwise.
- Reconocer límite APC (no separar edad/período/cohorte con 3 olas).
- Reconocer que cohortes jóvenes solo aparecen en olas recientes.
- El efecto contraintuitivo del particularismo (más reconocimiento de barreras → más justificación) necesita interpretación teórica, no esconderlo.
- Pseudo-R² bajos: normal en actitudes; reportar sin maquillar.
- Verificar wording exacto del ítem normativo de educación entre olas antes de usarlo como serie temporal.

## 12. Marco teórico (para depurar — está sobrecargado en la versión vieja)

La presentación previa amontonaba Marx, Weber, Durkheim, Bourdieu, Fraser, Therborn, Young, Sandel, Castillo, Bellei, Arenas de Mesa. **Para artículo: quedarse con 2–3 anclas** que sostengan directamente el argumento (candidatos fuertes: **Castillo** sobre meritocracia y justificación de la desigualdad en Chile; **Sandel** sobre la "tiranía del mérito"; literatura de **socialización política / cohortes** tipo Mannheim para el eje generacional). Integrar antecedentes empíricos con el marco (no en secciones separadas).
