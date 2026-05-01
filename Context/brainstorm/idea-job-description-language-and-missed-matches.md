# Project Idea: Job Description Language, Search Optimization, and Missed Matches

## Motivation

A large literature studies how specific kinds of job-description wording, especially gendered language, affect who applies. A broader question is whether the language of job ads shapes applicant pools in ways that are inefficient, even when there is no obvious exclusionary intent. In particular, employers may write ads to optimize visibility, searchability, or perceived professionalism in ways that unintentionally narrow the pool to workers who recognize the right keywords and labels.

This may generate missed matches. Workers can have the underlying skills needed for a job without recognizing themselves in the language of the posting. A candidate with applied mathematics or data skills, for example, may be a strong fit for a computational biology role but may not apply if the job is described using unfamiliar sector-specific keywords.

The `Rozee.pk` data create the possibility of studying whether job-description language affects not just the size or gender composition of the applicant pool, but the extent to which qualified workers fail to apply.

## Core Research Question

Does the language used in job descriptions narrow applicant pools by making jobs easier to find or recognize for workers who use the "right" keywords, while discouraging or excluding other workers who are good latent matches?

## Main Hypothesis

Job descriptions that are more optimized around narrow keywords, sector-specific labels, or standardized search language attract applicant pools that are more concentrated among workers whose profiles use the same terminology, even when other workers appear similarly well matched in underlying skills.

## Core Concept

The central distinction is between:

- `Observed keyword match`
  Whether the words in the applicant profile line up with the words in the job ad.
- `Latent skill match`
  Whether the applicant appears to have the underlying capabilities needed for the job, even if their profile uses different language.

The main idea is that some jobs may be written in ways that overweight observed keyword match relative to latent skill match. If so, those jobs may miss many plausible applicants.

## Proposed Measurement Strategy

The project would use AI or other text methods to build a richer semantic measure of match on both sides of the market.

### Step 1: Infer latent requirements from the job ad

Use the full job description, title, listed skills, and screening questions to infer:

- core tasks
- required technical skills
- likely adjacent skills
- required domain knowledge
- seniority
- occupation family

The goal is to recover the underlying skill bundle the job actually demands, not just the exact keywords used in the posting.

### Step 2: Infer latent skills from the applicant side

Use resumes, work histories, education, prior occupations, and application materials to infer:

- core skills
- adjacent skills
- task experience
- likely occupation family
- seniority
- transferable capabilities

The goal is to identify applicants who appear substantively well matched even if their resumes do not use the same labels as the job posting.

### Step 3: Compare latent match to observed application behavior

For each applicant-job pair in a relevant choice set, compare:

- semantic or latent fit
- surface-level keyword overlap
- whether the applicant actually applied

The key outcome is whether jobs with narrower or more keyword-dependent language have a larger set of plausible but unrealized matches.

## Main Outcomes

The project could study several related outcomes:

- whether keyword-heavy job descriptions attract narrower applicant pools
- whether applicant pools become more concentrated among workers using the same vocabulary as the ad
- whether there are many non-applicants with high latent match but low keyword overlap
- whether missed matches are especially common across adjacent fields
- whether firms using narrower language receive fewer diverse but plausible applicants

## Empirical Strategy

The strongest design would use detailed exposure data, such as:

- search logs
- job impressions
- job views
- saved jobs
- recommendation exposure

With those data, the main test would be: among applicants who were plausibly exposed to a job, are those with high latent fit but low keyword overlap less likely to apply?

If exposure data are limited, a weaker but still useful design would define choice sets using:

- jobs active in the applicant's market and search window
- jobs in related occupations or categories
- jobs matching broad experience and location constraints

That version is less clean because non-application may reflect non-exposure rather than non-recognition.

## Why This Could Be Interesting

This project speaks to a broader issue in online labor markets: digital matching systems may reward workers who know how to describe themselves in the platform's dominant language, not just workers with the strongest underlying skills. If so, search optimization can create inefficiency by narrowing the pool around visible keywords rather than actual fit.

This also connects employer behavior to platform design. Firms may think they are improving recruitment by using standardized or optimized language, but in practice they may be screening out strong candidates who would have been productive matches.

## Potential Contributions

- Move beyond the literature on gendered wording to a broader theory of linguistic narrowing in job search.
- Introduce a distinction between semantic fit and keyword fit in online labor markets.
- Measure unrealized matches rather than only realized applicants.
- Show how platform search and job-description conventions may reduce matching efficiency.

## Main Challenges

Several issues would need to be handled carefully:

- latent skill measures produced by AI need validation
- non-application is hard to interpret without exposure data
- some "missed matches" may reflect genuine preference differences rather than misunderstanding
- different occupations naturally rely on different amounts of specialized language
- keyword-rich ads may correlate with firm type, hiring sophistication, or job complexity

For these reasons, the most defensible version of the project should emphasize how job-description language shapes observed application behavior conditional on estimated latent fit, rather than claiming that all unrealized matches are mistakes.

## Possible Extensions

- Test whether narrower language is associated with better or worse hiring outcomes.
- Study whether linguistic narrowing is stronger in technical occupations than in generalist ones.
- Compare firms that post similar roles but describe them differently.
- Examine whether experienced platform users are better at applying across vocabulary boundaries.
- Test whether recommendation systems offset or reinforce keyword-based narrowing.
