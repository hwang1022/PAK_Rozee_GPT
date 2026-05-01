# Project Idea: Which Labor-Market Interventions Matter for Whom?

## Motivation

A large literature in labor economics, especially in developing-country settings, studies interventions intended to improve labor-market outcomes. These include information interventions, search assistance, application support, signaling and credentialing tools, screening reforms, transport support, and other efforts to reduce frictions between workers and jobs. Many of these interventions have credible evidence behind them, including randomized evidence.

But a successful intervention can still have limited aggregate relevance if the underlying friction only affects a small share of workers. The key question is not just whether an intervention works in a trial, but how many workers are actually positioned to benefit from that mechanism in the broader market.

The central idea of this project is to use large-scale platform data from `Rozee.pk` to map the prevalence of different labor-market frictions across the applicant pool. The goal is not to re-estimate treatment effects from prior interventions. Instead, the goal is to study the scope for different intervention classes to matter, and to show why heterogeneous targeting is central for policy relevance.

## Core Research Question

Among the labor-market frictions targeted by common interventions, which ones appear most prevalent in the platform population, and for what kinds of workers?

## Main Claim

Many labor-market interventions may be highly relevant for some segments of workers and largely irrelevant for others. Large-scale platform data can help quantify the potential target population for different intervention classes by showing which workers appear to face which frictions.

## Conceptual Framing

The paper would make a distinction between three objects:

- `Treatment effect`
  How much an intervention changes outcomes for treated workers in a specific study.
- `Friction prevalence`
  How many workers in the population appear to face the underlying constraint that the intervention is meant to relax.
- `Targeting relevance`
  How well an intervention can be directed toward the subset of workers for whom that friction is actually binding.

The project is about the second and third objects, not the first.

## Proposed Structure

The paper would proceed in three steps:

1. Review the labor-market intervention literature and classify interventions by the friction they target.
2. Use `Rozee.pk` data to construct descriptive proxies for which workers appear to face each friction.
3. Compare the prevalence of these frictions across the platform population and across worker subgroups.

## A Taxonomy of Intervention Classes

Below is a first-pass taxonomy of intervention classes and the friction each one targets.

### 1. Information Interventions

These interventions help workers learn about jobs, wages, occupations, or career paths they might not otherwise consider.

Examples:

- vacancy information
- labor-market information campaigns
- wage information
- occupation discovery interventions

Target friction:

- workers do not know which opportunities exist or which jobs they are plausibly suited for

### 2. Search-Broadening Interventions

These interventions help workers search more effectively or consider a broader set of jobs.

Examples:

- recommendation systems
- search coaching
- job alerts
- curated vacancy lists

Target friction:

- workers search too narrowly relative to their feasible opportunity set

### 3. Application-Support Interventions

These interventions help workers complete or improve applications.

Examples:

- CV assistance
- cover-letter support
- application reminders
- simplified application workflows

Target friction:

- workers fail to apply, or apply weakly, even when a job is a plausible fit

### 4. Signaling and Credentialing Interventions

These interventions improve how worker quality is communicated to employers.

Examples:

- certifications
- psychometric assessments
- skill badges
- verified credentials
- standardized testing

Target friction:

- workers' latent quality exceeds what is visible in their profiles or applications

### 5. Screening and Employer-Side Interventions

These interventions improve how firms identify strong candidates.

Examples:

- employer screening tools
- blind review
- structured shortlisting tools
- candidate ranking systems

Target friction:

- employers fail to recognize or act on strong candidates who do apply

### 6. Mobility or Access Interventions

These interventions relax geographic or logistical barriers.

Examples:

- transport subsidies
- relocation support
- interview travel support
- remote-work matching support

Target friction:

- workers face jobs that are plausible matches but practically inaccessible

## Platform-Based Proxies for Each Friction

The value of the `Rozee.pk` data is that they may allow descriptive measures of who appears to sit at each margin.

### A. Information Frictions

Workers plausibly facing information frictions may be those who:

- search only within a narrow subset of occupations despite having backgrounds consistent with adjacent jobs
- apply only to a small portion of jobs for which they appear qualified
- never view or search for categories where they have strong latent match
- shift behavior sharply after exposure to alerts, recommendations, or new information

Possible proxy:

- compare a worker's latent skill profile to nearby occupations or job categories they never search or view

### B. Search Frictions

Workers plausibly facing search frictions may be those who:

- repeatedly search using narrow or low-yield keywords
- concentrate applications within a very narrow band of jobs despite broad latent fit
- fail to explore geographically or occupationally adjacent jobs

Possible proxy:

- measure the gap between the breadth of jobs a worker could plausibly match and the breadth of jobs they actually search over or view

### C. Application Frictions

Workers plausibly facing application frictions may be those who:

- view jobs but do not apply
- start applications but do not complete them
- apply infrequently despite high activity on the platform
- submit low-effort or low-completeness applications

Possible proxy:

- among workers with high latent fit and observable exposure to jobs, identify those who fail to apply or submit weak applications

### D. Signaling Frictions

Workers plausibly facing signaling frictions may be those who:

- appear to have strong underlying skills or experience but weak observable credentials
- look qualified based on resume content or work history but receive little employer interest
- have backgrounds that are hard to summarize in standard platform fields

Possible proxy:

- compare latent fit inferred from full profile text and history to employer response conditional on observable tags, credentials, or profile fields

### E. Screening Frictions

Workers plausibly facing screening frictions may be those who:

- apply to jobs for which they appear strongly matched but are rarely viewed or shortlisted
- are similar in latent quality to shortlisted workers but are screened out
- perform well on external or common assessments but are not advanced by firms

Possible proxy:

- among actual applicants, compare latent fit to employer screening outcomes

### F. Mobility or Access Frictions

Workers plausibly facing access frictions may be those who:

- match jobs outside their immediate geography but do not apply
- search or click on distant jobs but do not convert into applications
- apply only within a narrow radius despite broader latent fit

Possible proxy:

- compare application behavior to plausible job matches as distance, relocation requirements, or location mismatch vary

## Main Empirical Exercise

The central empirical exercise would be descriptive but disciplined.

For each intervention class, construct a platform-based measure of the share of workers who appear to face the corresponding friction. Then compare those shares:

- across the full applicant population
- across worker subgroups
- across experience levels
- across cities and occupations
- across different points of the skill distribution

The output would not be "this intervention increases employment by X." Instead, it would be something like:

- this friction appears relevant for a large share of workers
- this friction appears concentrated among a narrow subgroup
- this intervention class has broad potential scope
- this intervention class appears highly targetable but not broadly relevant

## Why This Could Be Interesting

This project would contribute to the literature in several ways.

First, it would connect intervention evidence to market-wide descriptive evidence. Much of the existing literature is strong on internal validity but weaker on the question of how broadly a mechanism matters in the population.

Second, it would provide a framework for thinking about external validity through the lens of friction prevalence. Even if an intervention has a large treatment effect, its aggregate importance depends on how many workers are actually constrained on that margin.

Third, it would show why targeting matters. The same intervention can be highly valuable for a small subgroup and largely irrelevant for the median worker.

## Connection to Related Work

This idea is closely related to work that compares latent match to realized application or screening outcomes. For example, one can use a common assessment or a richer latent-quality measure to compare workers with jobs they did not pursue or firms that did not advance them. That logic helps separate:

- true lack of fit
- search or application frictions
- signaling failures
- screening mistakes

The proposed `Rozee.pk` project would extend that logic from one friction to a broader taxonomy of intervention-relevant margins.

## Main Challenges

Several issues will need careful handling.

- The proxies identify who appears exposed to a friction, not who would necessarily respond to an intervention.
- Some workers may face multiple frictions at once.
- Latent-fit measurement will require validation.
- Non-application is difficult to interpret without strong exposure data.
- Observed behavior may reflect preferences rather than constraints.
- Different occupations may naturally differ in how much search breadth or signaling ambiguity exists.

Because of these concerns, the paper should be framed in terms of `scope`, `relevance`, and `upper-bound target populations`, not direct treatment effects.

## A Useful Way To Position the Paper

One clean way to position the paper is:

"We use large-scale platform data to ask which labor-market frictions appear quantitatively important for which workers. Rather than estimating the effect of any one intervention, we map the population scope for different classes of interventions by identifying workers whose observed behavior is consistent with the friction those interventions are designed to address."

## Possible Extensions

- Combine the descriptive exercise with a focused literature review mapping intervention classes to friction types.
- Compare friction prevalence across low- and high-skill jobs.
- Compare prevalence across gender, geography, or experience groups.
- Study whether some frictions matter mostly at the top or bottom of the ability distribution.
- Use employer-side data to compare worker-side frictions with firm-side screening problems.
