/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

-- Making sure data imported correctly
 
Select *
From PortfolioProject.CovidDeaths
order by 3,4;

Select *
From PortfolioProject.covidvaccinations
order by 3,4;

-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject.CovidDeaths
order by 1,2;


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject.CovidDeaths
Where location like 'Ecuador'
order by 1,2;


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject.CovidDeaths
-- Where location like 'Bosnia and Herzegovina'
order by 1,2;


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject.CovidDeaths
Group by Location, Population
order by PercentPopulationInfected desc;


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as UNSIGNED)) as TotalDeathCount
From PortfolioProject.CovidDeaths
Where continent is not null 
Group by Location
order by TotalDeathCount desc;


-- Countries with Highest Death PERCENT per Population

SELECT 
  Location, 
  Population,
  MAX(CAST(Total_deaths AS UNSIGNED)) AS TotalDeathCount,
  (MAX(CAST(Total_deaths AS UNSIGNED)) / Population) * 100 AS death_percent
FROM PortfolioProject.CovidDeaths
GROUP BY Location, Population
ORDER BY death_percent DESC;




SHOW COLUMNS FROM PortfolioProject.CovidDeaths LIKE 'population';



-- BREAKING THINGS DOWN BY CONTINENT
-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as unsigned)) as TotalDeathCount
From PortfolioProject.CovidDeaths
Group by continent
order by TotalDeathCount desc;



-- GLOBAL NUMBERS

SELECT 
  `date`, 
  SUM(new_cases) AS total_cases, 
  SUM(CAST(new_deaths AS UNSIGNED)) AS total_deaths, 
  (SUM(CAST(new_deaths AS UNSIGNED)) / SUM(new_cases)) * 100 AS DeathPercentage
FROM PortfolioProject.CovidDeaths
GROUP BY `date`
ORDER BY `date`;






-- Total Population vs Vaccinations
/* shows daily COVID vaccination progress by country OR 
(a rolling total of people vaccinated over time (per country)) */

-- small tip : CONVERT(..., TYPE) and CAST(... AS TYPE) do the same thing

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(vac.new_vaccinations ,unsigned)) OVER( partition by dea.location ORDER BY dea.location, dea.date)
AS RollingPeopleVaccinated
From PortfolioProject.CovidDeaths dea
Join PortfolioProject.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
-- WHERE dea.location LIKE 'Mexico'
order by 2,3;


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(vac.new_vaccinations, unsigned)) OVER (Partition by dea.Location Order by dea.Date) AS RollingPeopleVaccinated
From PortfolioProject.CovidDeaths dea
Join PortfolioProject.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac;


-- Same as above but this time showing latest vaccination percent only for each country 

With PopvsVac2 (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated2)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(vac.new_vaccinations, unsigned)) OVER (Partition by dea.Location Order by dea.location) as RollingPeopleVaccinated2
-- , (RollingPeopleVaccinated/population)*100 {this is why I'm using CTE here}
From PortfolioProject.CovidDeaths dea
Join PortfolioProject.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
-- order by 2,3
)
Select *, (RollingPeopleVaccinated2/Population)*100
From PopvsVac2;




-- TEMP table
-- Using Temp Table to perform Calculation on Partition By in previous query
-- same as before but using TEMP table

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TEMPORARY Table if exists PercentPopulationVaccinated;
Create TEMPORARY Table PercentPopulationVaccinated
(
Continent varchar(255),
Location varchar(255),
Date varchar(255),
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
);

Insert into PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, 
NULLIF(vac.new_vaccinations, '') AS New_vaccinations
, SUM(CONVERT(NULLIF(vac.new_vaccinations, '') , UNSIGNED)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject.CovidDeaths dea
Join PortfolioProject.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date;
-- where dea.continent is not null 
-- order by 2,3;

Select *, (RollingPeopleVaccinated/Population)*100 AS RollingPeopleVaccinatedPercent
From PercentPopulationVaccinated;





-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(vac.new_vaccinations, unsigned)) 
OVER (Partition by dea.Location Order by dea.location, dea.Date)  RollingPeopleVaccinated
From PortfolioProject.CovidDeaths dea
Join PortfolioProject.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null ;

