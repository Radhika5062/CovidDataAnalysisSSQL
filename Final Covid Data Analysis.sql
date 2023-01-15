-- Assumption : 
-- icu_patients counts the total number of patients in ICU on that day.

select * from coviddeaths
order by location, dates;

-- World Population
select sum(population) as TotalWorldPopulation
from coviddeaths
where continent is not null;

-- When was the first case ever reported
select min(dates) as FirstCaseWorld
from coviddeaths 
where continent is not null 
and total_cases is not null

-- When was the first case ever reported and in which country
select location, dates, total_cases
from coviddeaths
where dates = (select min(dates) 
			   from coviddeaths 
			   where continent is not null 
			   and total_cases is not null
			  )
and total_cases is not null
and continent is not null;


-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract covid in said LOCATION
select location, dates, total_cases, total_deaths, round((total_deaths/total_cases) * 100,2) as DeathPercentagePerLocation
from coviddeaths
where continent is not null
order by 1, 2

--Shows the likelihood of dying if you contract covid in said CONTINET
select location, dates, total_cases, total_deaths, round((total_deaths/total_cases) * 100,2) as DeathPercentagePerContinent
from coviddeaths
where continent is null
order by 1, 2


-- Looking at Total Cases vs Population
-- Shows what percentage of population got covid per LOCATION
select location, dates, population, total_cases, round((total_cases/population) * 100,2) as PercentOfPopulationInfectedPerLocation
from coviddeaths
where continent is not null
order by 1, 2

--Shows the percentage of population got covid per CONTINENT
select location, dates, population, total_cases, 
round((total_cases/population) * 100,2) as PercentOfPopulationInfectedPerContinent
from coviddeaths
where continent is null
order by 1, 2

-- Looking at countries with highest infection rate compared to population
select location, population, max(total_cases) as HighestInfectionCount, 
round(max((total_cases/population) * 100),2) as PercentOfPopulationInfected
from coviddeaths
where continent is not null
group by location, population
order by PercentOfPopulationInfected desc

-- Looking at the LOCATION with highest death count per population
select location, max(total_deaths) as TotalDeathCount
from coviddeaths
where continent is not null
group by location
order by TotalDeathCount desc

-- Looking at the CONTINENT with highest death count per population
select location, max(total_deaths) as TotalDeathCount
from coviddeaths
where continent is null
group by location
order by TotalDeathCount desc

-- LET'S BREAK THINGs DOWN BY CONTINENT ( correct data )
select location, max(total_deaths) as TotalDeathCount
from coviddeaths
where continent is null
group by location
order by TotalDeathCount desc

-- Showing continents with the highest death count per population (For visualization only)
select continent, max(total_deaths) as TotalDeathCount
from coviddeaths
where continent is not null
group by continent
order by TotalDeathCount desc

-- GLOBAL NUMBERS
select dates, sum(new_cases) as TotalCases, sum(new_deaths) as TotalDeaths, ( sum(new_deaths)/sum(new_cases) ) * 100 as DeathPercentage
from coviddeaths
where continent is not null
group by dates
order by 1, 2

-- Overall numbers
select sum(new_cases) as TotalCases, sum(new_deaths) as TotalDeaths, ( sum(new_deaths)/sum(new_cases) ) * 100 as DeathPercentage
from coviddeaths
where continent is not null
order by 1, 2

-- Looking at Total Population Vs Vaccinations
select d.continent, d.location, d.dates, d.population, v.new_vaccinations
from coviddeaths d
join vaccination v
on d.location = v.location
and d.dates = v.dates
where d.continent is not null
order by 1, 2, 3;

-- Looking for Total Population Vs Vaccinations Rolling Sum
select d.continent, d.location, d.dates, d.population, v.new_vaccinations,
sum(v.new_vaccinations) over(partition by d.location order by d.location, d.dates) as 
rollingPeopleVaccinated
from coviddeaths d
inner join vaccination v
on d.location = v.location
and d.dates = v.dates
where d.continent is not null
order by 2, 3

-- USE CTE
-- What percentage of population is vaccinated each day
with popVsVac as
	(
		select d.continent, d.location, d.dates, d.population, v.new_vaccinations,
		sum(v.new_vaccinations) over(partition by d.location order by d.location, d.dates) as 
		rollingPeopleVaccinated
		from coviddeaths d
		inner join vaccination v
		on d.location = v.location
		and d.dates = v.dates
		where d.continent is not null
	)
select *, rollingPeopleVaccinated/population as rollingPeopleVaccinatedPercent
from popVsVac

-- Creating views to store data for later visualizations
create view PercentPopulationVaccinated as
select c.continent, c.location, c.dates, c.population, v.new_vaccinations,
sum(v.new_vaccinations) over(partition by c.location order by c.location, c.dates) as RollingPeopleVaccinated
from coviddeaths c
join vaccination v
on c.location = v.location
and c.dates = v.dates
where c.continent is not null


-- When was the first case reported in each LOCATION along with number of cases reported
with cte as 
	(
		select location, min(dates) as FirstCaseDate
		from coviddeaths
		where continent is not null
		and total_cases is not null
		group by location
		order by FirstCaseDate
	)
select c.location, c.FirstCaseDate, d.total_cases
from cte c
join coviddeaths d
on c.location = d.location
and c.FirstCaseDate = d.dates
order by c.FirstCaseDate

-- When was the first case reported in each COUNTRY along with the number of cases reported
with cte as 
	(
		select location, min(dates) as FirstCaseDate
		from coviddeaths
		where continent is null
		and total_cases is not null
		group by location
		order by FirstCaseDate
	)
select c.location, c.FirstCaseDate, d.total_cases
from cte c
join coviddeaths d
on c.location = d.location
and c.FirstCaseDate = d.dates

-- Total % of cases reported having patients in ICU per LOCATION
-- Shows the likelihood of being admitted to the ICU if you contract covid in said LOCATION per date
select location, dates, total_cases, icu_patients, ( icu_patients/total_cases ) * 100 as ICUPercentageVsTotalCases
from coviddeaths 
where continent is not null
order by ICUPercentageVsTotalCases

-- Highest death recorded in a day along with the date itself over all locations
with highestDeaths as
	(
		select max(new_deaths) as HighestDeathCount
		from coviddeaths
		where continent is not null
	)
select location, dates, total_cases, new_deaths
from coviddeaths
where new_deaths = (select HighestDeathCount from highestDeaths)

-- Highest deaths recorded in a day along with date itself for each location
select distinct location,
max(new_deaths) over( partition by location ) as maxDeathsRecordedinADay
from coviddeaths
where continent is not null
order by maxDeathsRecordedinADay desc

-- Highest number of total deaths in LOCATION
select location, total_deaths
from coviddeaths
where total_deaths  = ( select max(total_deaths) from coviddeaths where continent is not null )
and continent is not null

-- Top 5 locations with highest total death count
with findMaxTotalDeaths as
	(
		select location,
		max(total_deaths) as TotalDeathCount
		from coviddeaths
		group by location
	),
	cte as 
	(
		select f.location, f.TotalDeathCount,
		rank() over(order by f.TotalDeathCount desc) as rnk
		from findMaxTotalDeaths f
		join coviddeaths c
		on f.location = c.location
		and f.TotalDeathCount = c.total_deaths
		where c.continent is not null
		and c.total_deaths is not null
	)
select location, TotalDeathCount from cte where rnk <6

-- Simpler form of above query as in this case we are using the LIMIT function
select location, max(total_deaths) as m_total_deaths
from coviddeaths
where continent is not null
and total_deaths is not null
group by location 
order by m_total_deaths desc
limit 5

-- Fully vaccinated count for each LOCATION and the date
with cte as 
	(
		select location, max(people_fully_vaccinated) as TotalFullyVaccinatedCount
		from vaccination
		group by location
	)
select c.location, c.TotalFullyVaccinatedCount, v.dates
from vaccination v
join cte c
on v.location = c.location
and v.people_fully_vaccinated = c.TotalFullyVaccinatedCount
and v.continent is not null
order by c.location

-- Fully vaccinated count for each LOCATION and the date
with cte as 
	(
		select location, max(people_fully_vaccinated) as TotalFullyVaccinatedCount
		from vaccination
		where continent is null
		group by location
	)
select c.location, c.TotalFullyVaccinatedCount, v.dates
from vaccination v
join cte c
on v.location = c.location
and v.people_fully_vaccinated = c.TotalFullyVaccinatedCount
and v.continent is null
order by c.location


-- Total number of fully vaccinated people as compared to population per LOCATION

with getMaxFullyVaccinatedCount as 
	(
		select location, max(people_fully_vaccinated) over (partition by location) as FullyVaccinatedCount
		from vaccination
		where continent is not null
	),
	getDatesAlongWithFullyVaccinatedCount as
	(
		select distinct v.location, v.dates, g.FullyVaccinatedCount as FullyVaccinatedCount
		from vaccination v
		join getMaxFullyVaccinatedCount g
		on v.location = g.location
		and v.people_fully_vaccinated = g.FullyVaccinatedCount
	)
select c.location, c.dates, g.FullyVaccinatedCount, c.population, 
round((g.FullyVaccinatedCount/c.population) * 100, 2) as PercentOfPolulationFullyVaccinated
from coviddeaths c
join getDatesAlongWithFullyVaccinatedCount g
on c.location = g.location
and c.dates = g.dates