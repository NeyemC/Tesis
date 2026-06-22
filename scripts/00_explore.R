# =====================================================================
# 00_explore.R — Verificación de variables ISSP 1999/2009/2019 (Chile)
# Objetivo: confirmar el mapeo de variables del CONTEXTO_TESIS.md
# =====================================================================

suppressMessages({library(haven); library(dplyr)})

ip <- "input"
f99 <- file.path(ip, "ZA3430_2006-09-14.sav")
f09 <- file.path(ip, "ZA5400_v4-0-0.sav")
f19 <- file.path(ip, "ZA7600_v3-0-0.sav")

cat("=== Leyendo olas ===\n")
d99 <- read_sav(f99); cat("1999:", nrow(d99), "x", ncol(d99), "\n")
d09 <- read_sav(f09); cat("2009:", nrow(d09), "x", ncol(d09), "\n")
d19 <- read_sav(f19); cat("2019:", nrow(d19), "x", ncol(d19), "\n")

look <- function(d, v){
  if(!v %in% names(d)){ cat(sprintf("  [%s] NO EXISTE\n", v)); return(invisible()) }
  lab <- attr(d[[v]], "label"); lab <- ifelse(is.null(lab), "", lab)
  cat(sprintf("  [%s] %s\n", v, lab))
}

cat("\n=== Variable país y filtro Chile ===\n")
cat("1999 V3 (country):\n"); print(head(sort(unique(zap_labels(d99$V3))), 40))
cat("2009 V5 (country):\n"); print(head(sort(unique(zap_labels(d09$V5))), 40))
cat("2019 c_alphan (country):\n"); print(head(sort(unique(as.character(d19$c_alphan))), 60))

cat("\n=== 1999: variables clave ===\n")
for(v in c("V3","V39","V40","V50","AGE","SEX","V6","V7")) look(d99, v)
cat("\n=== 2009: variables clave ===\n")
for(v in c("V5","V38","V39","V48","AGE","SEX","V6","V7","V8","V9","V10","V11","V12","V13","V14","V15","V16")) look(d09, v)
cat("\n=== 2019: variables clave ===\n")
for(v in c("c_alphan","v30","v31","v45","AGE","SEX","v1","v2","v3","v4","v5","v6","v7","v8","v9","v10")) look(d19, v)

cat("\n=== Buscar variables de PESO/ponderador en cada ola ===\n")
cat("1999:", grep("eight|actor|WGT|wgt", names(d99), value=TRUE), "\n")
cat("2009:", grep("eight|actor|WGT|wgt", names(d09), value=TRUE), "\n")
cat("2019:", grep("eight|actor|WGT|wgt|WEIGHT", names(d19), value=TRUE), "\n")

cat("\n=== Buscar AGE / edad / birth en 2019 (nombres en minúscula) ===\n")
cat("2019 age-like:", grep("age|AGE|birth|BIRTH|yrbrn", names(d19), value=TRUE), "\n")
cat("2019 sex-like:", grep("sex|SEX", names(d19), value=TRUE), "\n")
