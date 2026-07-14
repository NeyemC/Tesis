# =====================================================================
# 02_build_data.R — Construcción del dataset pooled ISSP Chile 1999/2009/2019
# Producto: input/issp_pooled.rds  (formato long, una fila por encuestado)
# =====================================================================
suppressMessages({library(haven); library(dplyr); library(tidyr)})

ip <- "input"
d99 <- read_sav(file.path(ip,"ZA3430_2006-09-14.sav"))
d09 <- read_sav(file.path(ip,"ZA5400_v4-0-0.sav"))
d19 <- read_sav(file.path(ip,"ZA7600_v3-0-0.sav"))

# --- helpers -------------------------------------------------------
# Lleva a numérico crudo y deja NA todo lo que no esté en 1:k (perdidos 0/7/8/9, -8/-9, etc.)
z <- function(x) zap_labels(x)
clean_k <- function(x, k=5){ x <- z(x); x[!(x %in% 1:k)] <- NA; x }
inv5 <- function(x){ 6 - clean_k(x, 5) }            # invierte escala 1..5 -> mayor = más
num  <- function(x){ x <- z(x); x }
# Religiosidad desde ATTEND (0=sin religión,1=varias/sem ... 8=nunca, 97/98/99=perdido)
# Recodifica a 0..8 con MAYOR = MÁS religioso. 0(sin religión) y 8(nunca) -> baja religiosidad.
relig_from_attend <- function(x){
  a <- z(x); a[!(a %in% 0:8)] <- NA
  out <- ifelse(a==0, 0, 9 - a)   # a=1(varias/sem)->8 ; a=8(nunca)->1 ; a=0(sin relig)->0
  out
}

# --- 1999 ----------------------------------------------------------
c99 <- d99 %>% filter(z(V3)==30) %>% transmute(
  ola        = 1999L,
  weight     = num(WEIGHT),
  edad       = num(AGE),
  mujer      = ifelse(z(SEX)==2, 1L, ifelse(z(SEX)==1, 0L, NA_integer_)),
  educ_anios = { e <- num(EDUCYRS); e[e<0 | e>60] <- NA; e },
  religiosidad= relig_from_attend(ATTEND),
  party_lr   = clean_k(PARTY_LR, 5),         # izquierda(1)-derecha(5)
  # VD: invertir para que MAYOR = MÁS justifica la desigualdad
  just_salud = inv5(V39),
  just_educ  = inv5(V40),
  # meritocracia normativa (importancia educación para el pago) invertida
  merit_norm_educ = inv5(V50),
  # baterías getting-ahead / particularismo: NO existen en 1999
  ga_familia=NA_real_, ga_padres=NA_real_, ga_educ=NA_real_, ga_ambic=NA_real_,
  ga_trabajo=NA_real_, ga_gente=NA_real_, ga_polit=NA_real_, ga_coimas=NA_real_,
  ga_raza=NA_real_, ga_relig=NA_real_, ga_sexo=NA_real_
)

# --- 2009 ----------------------------------------------------------
c09 <- d09 %>% filter(z(V5)==152) %>% transmute(
  ola        = 2009L,
  weight     = num(WEIGHT),
  edad       = num(AGE),
  mujer      = ifelse(z(SEX)==2, 1L, ifelse(z(SEX)==1, 0L, NA_integer_)),
  educ_anios = { e <- num(EDUCYRS); e[e<0 | e>60] <- NA; e },
  religiosidad= relig_from_attend(ATTEND),
  party_lr   = clean_k(PARTY_LR, 5),
  just_salud = inv5(V38),
  just_educ  = inv5(V39),
  merit_norm_educ = inv5(V48),
  ga_familia = inv5(V6),  ga_padres = inv5(V7),  ga_educ = inv5(V8),
  ga_ambic   = inv5(V9),  ga_trabajo= inv5(V10), ga_gente= inv5(V11),
  ga_polit   = inv5(V12), ga_coimas = inv5(V13), ga_raza = inv5(V14),
  ga_relig   = inv5(V15), ga_sexo   = inv5(V16)
)

# --- 2019 (sin "ambición") ----------------------------------------
c19 <- d19 %>% filter(as.character(c_alphan)=="CL") %>% transmute(
  ola        = 2019L,
  weight     = num(WEIGHT),
  edad       = num(AGE),
  mujer      = ifelse(z(SEX)==2, 1L, ifelse(z(SEX)==1, 0L, NA_integer_)),
  educ_anios = { e <- num(EDUCYRS); e[e<0 | e>60] <- NA; e },
  religiosidad= relig_from_attend(ATTEND),
  party_lr   = clean_k(PARTY_LR, 5),
  just_salud = inv5(v30),
  just_educ  = inv5(v31),
  merit_norm_educ = inv5(v45),
  ga_familia = inv5(v1),  ga_padres = inv5(v2),  ga_educ = inv5(v3),
  ga_ambic   = NA_real_,                                   # no medido en 2019
  ga_trabajo = inv5(v4),  ga_gente = inv5(v5),
  ga_polit   = inv5(v6),  ga_coimas = inv5(v7),  ga_raza = inv5(v8),
  ga_relig   = inv5(v9),  ga_sexo   = inv5(v10)
)

# --- Pool ----------------------------------------------------------
dat <- bind_rows(c99, c09, c19)

# --- Cohorte (año de nacimiento ≈ ola - edad) ----------------------
dat <- dat %>% mutate(
  anio_nac = ola - edad,
  cohorte = cut(anio_nac,
                breaks = c(-Inf, 1958, 1973, 1990, Inf),
                labels = c("Desarrollista","Dictadura","Transicion","Neoliberal")),
  cohorte = factor(cohorte, levels=c("Desarrollista","Dictadura","Transicion","Neoliberal")),
  ola_f = factor(ola)
)

# --- Índices (promedio de ítems; mayor = más adhesión) -------------
mk_index <- function(df, items){ m <- as.matrix(df[items]); rowMeans(m, na.rm=TRUE) }
# requiere al menos la mitad de los ítems no-NA, si no -> NA
mk_index_min <- function(df, items, minprop=0.5){
  m <- as.matrix(df[items]); ok <- rowMeans(!is.na(m)) >= minprop
  out <- rowMeans(m, na.rm=TRUE); out[!ok] <- NA; out
}

# Meritocracia descriptiva comparable 2009-2019 (educación propia + trabajo duro)
dat$merit_desc <- mk_index_min(dat, c("ga_educ","ga_trabajo"))
# Particularismo / barreras adscriptivas (intacto 2009 y 2019)
dat$particularismo <- mk_index_min(dat,
  c("ga_raza","ga_sexo","ga_relig","ga_coimas","ga_polit","ga_familia"))

# --- Estandarización (z) dentro del pool, para predictores ---------
zscore <- function(x) as.numeric(scale(x))
dat <- dat %>% mutate(
  z_merit_desc = zscore(merit_desc),
  z_particular = zscore(particularismo),
  z_merit_norm = zscore(merit_norm_educ),
  z_educ       = zscore(educ_anios),
  z_relig      = zscore(religiosidad),
  z_party      = zscore(party_lr),
  z_edad       = zscore(edad)
)

# --- Guardar -------------------------------------------------------
saveRDS(dat, file.path(ip,"issp_pooled.rds"))

# --- Reporte rápido ------------------------------------------------
cat("Dataset pooled:", nrow(dat), "filas x", ncol(dat), "columnas\n\n")
cat("N por ola:\n"); print(table(dat$ola))
cat("\nCohorte x ola (conteo):\n"); print(table(dat$cohorte, dat$ola, useNA="ifany"))
cat("\nDirección ATTEND (1=alta freq? revisar etiqueta):\n")
print(attr(d09$ATTEND,"labels"))
cat("\nDirección PARTY_LR:\n")
print(attr(d09$PARTY_LR,"labels"))
cat("\nResumen VD y predictores:\n")
print(summary(dat[c("just_salud","just_educ","merit_desc","particularismo","merit_norm_educ","educ_anios","religiosidad","party_lr")]))
cat("\nNA% por variable clave:\n")
print(round(colMeans(is.na(dat[c("just_salud","just_educ","merit_desc","particularismo","merit_norm_educ","educ_anios","religiosidad","party_lr","weight")]))*100,1))
