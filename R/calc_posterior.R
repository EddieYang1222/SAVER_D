#' Calculates SAVER posterior
#'
#' Given prediction and prior variance, calculates the Gamma posterior
#' distribution parameters for a single gene.
#'
#' Let \eqn{\alpha} be the shape parameter and \eqn{\beta} be the rate
#' parameter of the prior Gamma distribution. Then, the posterior Gamma
#' distribution will be
#' \deqn{Gamma(y + \alpha, sf + \beta),}
#' where y is the observed gene count and sf is the size factor.
#'
#' @param y A vector of observed gene counts.
#'
#' @param mu A vector of prior means.
#'
#' @param sf Vector of normalized size factors.
#'
#' @param scale.sf Mean of the original size factors.
#'
#' @return A list with the following components
#' \item{\code{estimate}}{Recovered (normalized) expression}
#' \item{\code{se}}{Standard error of expression estimate}
#'
#' @importFrom stats qgamma
#' @export
calc.post <- function(y, mu, sf, scale.sf) {
  n <- length(y)
  if (length(mu) == 1) {
    mu <- rep(mu, n)
  }
  if (length(sf) == 1) {
    sf <- rep(sf, n)
  }
  if (sum(y) == 0) {
    return(list(estimate = rep(0, n), se = rep(0, n), rep(0, n), rep(0, n), rep(0, n), 0, 0, 0, rep(0,n)))
  }
  if (var(mu) == 0) {
    prior.beta <- rep(calc.b(y, mu, sf)[1], n)
    prior.alpha <- mu*prior.beta
    a <- c(0, Inf)
    b <- c(0, Inf)
    k <- c(0, Inf)
  } else{
    a <- tryCatch(calc.a(y, mu, sf), error = function(cond) {
      return(c(0, Inf))
    })
    b <- tryCatch(calc.b(y, mu, sf), error = function(cond) {
      return(c(0, Inf))
    })
    k <- tryCatch(calc.k(y, mu, sf), error = function(cond) {
      return(c(0, Inf))
    })
    var.method <- which.min(c(a[2], b[2], k[2]))

    if (var.method == 1) {
      prior.alpha <- a[1]
      prior.beta <- a[1]/mu
    } else if (var.method == 2) {
      prior.beta <- b[1]
      prior.alpha <- mu*b[1]
    } else {
      prior.alpha <- mu^2/k[1]
      prior.beta <- mu/k[1]
    }
  }
  
  
  prior.alpha.a <- a[1]
  prior.beta.a <- a[1]/mu
  post.alpha.a <- prior.alpha.a + y
  post.beta.a <- prior.beta.a + sf
  
  prior.alpha.b <- mu*b[1]
  prior.beta.b <- b[1]
  post.alpha.b <- prior.alpha.b + y
  post.beta.b <- prior.beta.b + sf
  
  prior.alpha.k <- mu^2/k[1]
  prior.beta.k <- mu/k[1]
  post.alpha.k <- prior.alpha.k + y
  post.beta.k <- prior.beta.k + sf
  
  post.alpha <- prior.alpha + y
  post.beta <- prior.beta + sf
  lambda.hat <- post.alpha/post.beta
  se <- sqrt(post.alpha/post.beta^2)
  
  se.a <- sqrt(post.alpha.a/post.beta.a^2)
  se.b <- sqrt(post.alpha.b/post.beta.b^2)
  if (k[1] != 0) {
    se.k <- sqrt(post.alpha.k/post.beta.k^2)
  } else { 
      se.k <- rep(0, n)
  }
  

  return(list(estimate = unname(ceiling(lambda.hat*1000*scale.sf)/1000),
              se = unname(ceiling(se*1000*scale.sf)/1000),
              a[1],
              b[1],
              k[1],
              a[2],
              b[2],
              k[2],
              mu))
}
