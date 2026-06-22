# =====================================================================
# 03_analysis.R — Fiabilidad, descriptivos y modelos ordered logit
# =====================================================================
suppressMessages({library(dplyr); library(psych); library(survey); library(MASS)})
options(width=120)
dat <- readRDS("input/issp_pooled.rds")

cat("############### 1. FIABILIDAD (alpha de Cronbach) ###############\n")
items_part <- c("ga_raza","ga_sexo","ga_relig","ga_coimas","ga_polit","ga_familia")
items_md   <- c("ga_educ","ga_trabajo")
for(w in c(2009,2019)){
  sub <- dat %>% filter(ola==w)
  a_p <- suppressWarnings(psych::alpha(sub[items_part], warnings=FALSE)$total$raw_alpha)
  r_md<- cor(sub$ga_educ, sub$ga_trabajo, use="complete.obs")
  cat(sprintf("Ola %d  | alpha particularismo (6 it)= %.3f | r(educ,trabajo)= %.3f\n", w, a_p, r_md))
}

cat("\n############### 2. DESCRIPTIVOS PONDERADOS POR OLA ###############\n")
wmean <- function(x,w){ ok<-!is.na(x)&!is.na(w); sum(x[ok]*w[ok])/sum(w[ok]) }
desc_ola <- dat %>% group_by(ola) %>% summarise(
  n=n(),
  just_salud = wmean(just_salud, weight),
  just_educ  = wmean(just_educ, weight),
  merit_norm = wmean(merit_norm_educ, weight),
  merit_desc = wmean(merit_desc, weight),
  particular = wmean(particularismo, weight),
  .groups="drop")
print(as.data.frame(desc_ola), digits=3)

cat("\n############### 3. DESCRIPTIVOS VD POR COHORTE x OLA ###############\n")
desc_coh <- dat %>% group_by(ola, cohorte) %>% summarise(
  n=n(),
  just_salud=wmean(just_salud,weight),
  just_educ =wmean(just_educ,weight),
  merit_desc=wmean(merit_desc,weight), .groups="drop")
print(as.data.frame(desc_coh), digits=3)

cat("\n############### 4. CORRELACIONES (2009+2019) ###############\n")
sub2 <- dat %>% filter(ola %in% c(2009,2019))
cm <- cor(sub2[c("just_salud","just_educ","merit_desc","particularismo","merit_norm_educ","educ_anios")],
          use="pairwise.complete.obs")
print(round(cm,3))

cat("\n############### 5. ORDERED LOGIT (svyolr) 2009+2019 ###############\n")
# Submuestra mecanismo: olas 2009 y 2019 con índices ricos
md <- dat %>% filter(ola %in% c(2009,2019)) %>%
  mutate(just_salud_f = factor(just_salud, ordered=TRUE),
         just_educ_f  = factor(just_educ , ordered=TRUE),
         mujer = factor(mujer))

tidy_olr <- function(m){
  s <- summary(m)$coefficients
  # z y p para svyolr
  est <- s[,1]; se <- s[,2]; z <- est/se; p <- 2*pnorm(-abs(z))
  data.frame(term=rownames(s), OR=round(exp(est),3), coef=round(est,3),
             se=round(se,3), z=round(z,2), p=round(p,4), row.names=NULL)
}

run_dv <- function(dvf, label){
  cat("\n========== VD:", label, "==========\n")
  d <- md %>% filter(!is.na(.data[[dvf]]), !is.na(z_merit_desc), !is.na(z_particular),
                     !is.na(z_educ), !is.na(z_relig), !is.na(mujer), !is.na(cohorte))
  des <- svydesign(ids=~1, weights=~weight, data=d)
  f_base <- as.formula(paste(dvf,"~ z_merit_desc + z_particular + z_educ + z_relig + mujer + cohorte + ola_f"))
  f_int  <- as.formula(paste(dvf,"~ z_merit_desc*cohorte + z_particular + z_educ + z_relig + mujer + ola_f"))
  m0 <- svyolr(f_base, design=des)
  m1 <- svyolr(f_int , design=des)
  cat("N =", nrow(d), "\n\n--- Modelo BASE ---\n"); print(tidy_olr(m0))
  cat("\n--- Modelo INTERACCIÓN merit_desc x cohorte ---\n"); print(tidy_olr(m1))
  invisible(list(m0=m0,m1=m1,d=d))
}
rs <- run_dv("just_salud_f","Justifica desigualdad SALUD")
re <- run_dv("just_educ_f" ,"Justifica desigualdad EDUCACIÓN")

cat("\n############### 6. EFECTO MARGINAL DE merit_desc POR COHORTE (salud) ###############\n")
# pendiente de z_merit_desc dentro de cada cohorte = beta_main + beta_interaccion
co <- coef(rs$m1)
b_main <- co["z_merit_desc"]
cat(sprintf("Desarrollista (ref): %.3f\n", b_main))
for(k in c("Dictadura","Transicion","Neoliberal")){
  nm <- paste0("z_merit_desc:cohorte",k)
  if(nm %in% names(co)) cat(sprintf("%-13s: %.3f\n", k, b_main + co[nm]))
}

saveRDS(list(rs=rs, re=re), "output/models.rds")
cat("\nOK. Modelos guardados en output/models.rds\n")
