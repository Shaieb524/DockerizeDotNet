
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebApiDb.Context;

namespace DotNetApi.Controllers
{
    [ApiController]
    [Route("health")]
    [AllowAnonymous]
    public class HealthCheckController : ControllerBase
    {
        private readonly ApplicationDbContext _appDb;

        public HealthCheckController(
            ApplicationDbContext appDb)
        {
            _appDb = appDb;
        }

        [HttpGet]
        [Produces("application/json")]
        public async Task<IActionResult> Get()
        {
            var dbStatuses = await CheckAllDatabases();
            var sqlServerStatus = dbStatuses.Any(x => x.Value == "Healthy") ? "Healthy" : "Unhealthy";

            var response = new
            {
                status = new
                {
                    webServer = "Healthy",
                    sqlServer = sqlServerStatus,
                    databases = dbStatuses
                },
                timestamp = DateTime.UtcNow,
                version = "1.0"
            };

            return sqlServerStatus == "Healthy" ? Ok(response) : StatusCode(503, response);
        }

        private async Task<Dictionary<string, string>> CheckAllDatabases()
        {
            var statuses = new Dictionary<string, string>();

            var dbChecks = new (string Name, DbContext Context)[]
            {
                (Name: "AppDb", Context: _appDb),
            };

            foreach (var db in dbChecks)
            {
                try
                {
                    var canConnect = await db.Context.Database.CanConnectAsync();
                    statuses[db.Name] = canConnect ? "Healthy" : "Unhealthy";
                }
                catch (Exception)
                {
                    statuses[db.Name] = "Unhealthy";
                }
            }

            return statuses;
        }
    }
}