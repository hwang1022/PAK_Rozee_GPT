# Project Idea: Applicant Heterogeneity and Application Standardization Over Time

## Motivation

Over the 15-year history of `Rozee.pk`, online job search became more widespread and more normalized. As workers spent more time on digital labor platforms, they may have learned what a "good" application looks like and adjusted their behavior accordingly. Even before the arrival of large language models, online platforms may already have pushed jobseekers toward more standardized forms of self-presentation.

This project asks whether applicant pools and application materials became more homogeneous over time. The broader motivation is to establish a pre-LLM baseline for how digital job platforms themselves may compress variation in how workers search for jobs and present themselves to employers.

## Core Research Question

Did applicants to the same job become more similar to one another over time, both in observable characteristics and in the content and style of their applications?

## Main Hypothesis

As online job search matured, applicants increasingly converged on shared norms of what constitutes a strong application. This would show up as a decline over time in the heterogeneity of applicants to a given vacancy and in the variation across the application materials submitted to that vacancy.

## What We Would Measure

The core unit of analysis would be the applicant pool to a given job posting.

For each posting, we could measure heterogeneity across applicants in:

- education
- years of experience
- prior occupations or industries
- location
- skills
- salary expectations
- gender, if observed

We could also measure heterogeneity in application materials, including:

- length of the application or cover letter
- lexical diversity
- similarity across applicants' text
- similarity between application materials and the job description
- use of common phrases or templated language

These outcomes would let us study both convergence in applicant composition and convergence in applicant presentation.

## Empirical Strategy

The main exercise would track whether similar jobs receive more homogeneous applicant pools in later years of the platform.

The cleanest version would compare postings within narrowly defined groups, controlling for:

- occupation or job category
- location
- employer or firm fixed effects, where possible
- salary range
- education and experience requirements
- applicant pool size
- year effects

The goal is to ask whether, conditional on similar vacancies, applications become less dispersed over time.

A stronger version would focus on firms posting similar jobs repeatedly over time. That would help isolate whether the same kinds of vacancies begin attracting more standardized applicant pools.

## Interpretation

A decline in heterogeneity could reflect several mechanisms:

- applicants learn what employers on the platform reward
- the platform itself standardizes applications through templates and search tools
- online search becomes more mainstream, causing more workers to target jobs in similar ways

The project would not identify the causal effect of LLMs. Instead, it would document a pre-LLM trend toward standardization in online labor markets. That baseline would be useful for thinking about whether LLMs are likely to amplify a process that was already underway.

## Why This Could Be Interesting

This project speaks to a broader question in labor markets: does digitization expand access and information, or does it also compress behavioral variation by teaching workers to conform to a narrower template? The `Rozee.pk` data are unusually well suited to this question because they contain a long time series of applications, applicant histories, and application materials submitted to specific vacancies.

It also creates a bridge to current debates about AI-generated job applications. If applications were already becoming more standardized before LLMs, then the effect of generative AI should be understood as building on an existing trend rather than creating standardization from scratch.

## Main Challenges

Several threats to interpretation would need to be addressed:

- the composition of workers on the platform may change over time
- the composition of firms and posted jobs may change over time
- `Rozee.pk` may have expanded across cities, sectors, or worker types
- the platform interface or application workflow may have changed
- some apparent convergence may reflect better job targeting rather than standardized behavior

Because of these concerns, the writeup should frame the exercise as documenting trends in standardization on a maturing online labor platform, rather than making a strong causal claim about internet adoption or AI.

## Possible Extensions

- Compare convergence in applicant observables to convergence in text.
- Test whether standardization is stronger in occupations with more applicants or more competition.
- Test whether more experienced platform users submit more standardized applications.
- Examine whether employer screening behavior becomes more or less selective as applicant pools converge.
- If the platform later reaches the LLM era, compare pre- and post-LLM trends.
