/* This file contains queries used to create a tableau dashboard.
	The link to the tableau dashboard is provided in the last query.
*/


-- Viewing CovidDeaths dataset
select * from PortfolioProject..CovidDeaths

/* Some useful columns to be used: 
	continent, location, date, population, total_cases, new_cases, total_deaths, new_deaths
*/


-- 1. Total cases by continent

select distinct(continent) from PortfolioProject..CovidDeaths;
-- We have to remove null values from Continent

select
	continent, location, date, sum(new_cases) as total_cases
from 
	PortfolioProject..CovidDeaths
where continent is not null
group by continent, location, date
order by 1, 2 desc;




-- 2. Total Cases vs Total Deaths (month wise)

select distinct(location) from PortfolioProject..CovidDeaths where continent is null;

/* High income, Low income, Lower middle income, Upper middle income, World. European Union is part of Europe.
	These values should not be in location column. So, we need to filter the column for other values.
*/

select
	continent, location, date, sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, 
	(case when sum(new_cases) = 0 then null
		else concat(round((sum(new_deaths)/sum(new_cases))*100,2), ' %')
		end) as DeathPercentage
from 
	PortfolioProject..CovidDeaths
where continent is not null
group by continent, location, date
order by 1,2,3;




--  3. Total Death Count 
select 
	continent, location, date, MAX(cast(total_deaths as int)) as TotalDeathCount
from 
	PortfolioProject..CovidDeaths
where continent is not null
group by continent, location, date
order by TotalDeathCount desc;




-- 4. Highest Infection Count and Maximum Population Infected Percent
select 
	continent, location, date, population, max(total_cases) as HighestInfectionCount,  
	max((total_cases/population))*100 as PercentPopulationInfected
from 
	PortfolioProject..CovidDeaths
group by continent, location, population, date
order by PercentPopulationInfected desc;




-- Now moving to the Vaccinations table
select * from PortfolioProject..CovidVaccinations;

/* Some useful columns to be used :
	continent, location, date, total_tests, new_tests, positive_rate, total_vaccinations, new_vaccinations, people_fully_vaccinated
*/

-- 5. Total Vaccinations vs People Fully Vaccinated
select 
	vac.continent, vac.location, vac.date, dea.population, sum(vac.total_vaccinations) as TotalVaccinations, sum(vac.people_fully_vaccinated) as PeopleFullyVacinated
from 
	PortfolioProject..CovidVaccinations vac
	join PortfolioProject..CovidDeaths dea
	on vac.location = dea.location and vac.date = dea.date
where vac.continent is not null 
group by vac.continent, vac.location, vac.date, dea.population
order by 1,2;




-- Some other queries


-- Total Population vs Vaccination
-- worldwide
select 
	dea.location, dea.date, dea.population,
	vac.new_vaccinations, 
	sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
	join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location and dea.date = vac.date
where dea.continent is null and dea.location not in ('European Union', 'High income', 'Low income', 'Lower middle income', 'Upper middle income', 'World')
order by 1,2

-- India
select 
	dea.location, dea.date, dea.population,
	vac.new_vaccinations, 
	sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
	join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location and dea.date = vac.date
where dea.location = 'India'
order by 1,2;




-- Using CTE
-- Total Population vs RollingPeopleVaccinated 
-- worldwide
with PopvsRolVac (Continent, Location, Date, Population, NewVaccinations, RollingPeopleVaccinated)
as (
select 
	vac.continent, vac.location, dea.date, dea.population, 
	vac.new_vaccinations,
	sum(vac.new_vaccinations) over (partition by vac.location order by vac.location, dea.date) as RollingPeopleVaccinated
from 
	PortfolioProject..CovidVaccinations vac
	join PortfolioProject..CovidDeaths dea
	on vac.location = dea.location and vac.date = dea.date
where vac.continent is not null and vac.location not in ('European Union', 'High income', 'Low income', 'Lower middle income', 'Upper middle income', 'World')
)
select
	*,
	round((RollingPeopleVaccinated/Population)*100, 2) as PercetnRollingPeopleVaccinated
from 
	PopvsRolVac
order by 1,2,3;

-- India
with PopvsRolVac (Continent, Location, Date, Population, NewVaccinations, RollingPeopleVaccinated)
as (
select 
	vac.continent, vac.location, dea.date, dea.population, 
	vac.new_vaccinations,
	sum(vac.new_vaccinations) over (partition by vac.location order by vac.location, dea.date) as RollingPeopleVaccinated
from 
	PortfolioProject..CovidVaccinations vac
	join PortfolioProject..CovidDeaths dea
	on vac.location = dea.location and vac.date = dea.date
where vac.continent = 'Asia' and vac.location = 'India'
)
select
	*,
	round((RollingPeopleVaccinated/Population)*100, 2) as PercetnRollingPeopleVaccinated
from 
	PopvsRolVac
order by 1,2,3;




-- Creating view to store data
Create View PercentPopulationVaccinated as
select 
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
from 
	PortfolioProject..CovidDeaths dea
	join PortfolioProject..CovidVaccinations vac
		on dea.location = vac.location
		and dea.date = vac.date
where dea.continent is not null;

select * from PercentPopulationVaccinated;




/* Creating a table named Project containing two columns (ProjectName and Link)
	and then inserting the project name ProjectName and link to the tableau visual for this project.
*/
drop table if exists Project; 
create table Project (
ProjectName varchar(200),
Link varchar(255)
);

insert into Project(ProjectName, Link)
values ('SqlQuriesForTableau', 'https://public.tableau.com/app/profile/prasoon.bisht/viz/CovidDataAnalysis_17097424474460/Dashboard1');

select * from Project;