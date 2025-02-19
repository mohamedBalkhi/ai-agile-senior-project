using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Senior.AgileAI.BaseMgt.Api.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "public");

            migrationBuilder.CreateTable(
                name: "Countries",
                schema: "public",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Code = table.Column<string>(type: "text", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    UpdatedDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Countries", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Users",
                schema: "public",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Email = table.Column<string>(type: "text", nullable: false),
                    Password = table.Column<string>(type: "text", nullable: false),
                    BirthDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Country_IdCountry = table.Column<Guid>(type: "uuid", nullable: false),
                    Status = table.Column<string>(type: "text", nullable: false),
                    isAdmin = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    UpdatedDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Users", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Users_Countries_Country_IdCountry",
                        column: x => x.Country_IdCountry,
                        principalSchema: "public",
                        principalTable: "Countries",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "OrganizationMembers",
                schema: "public",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    Organization_IdOrganization = table.Column<Guid>(type: "uuid", nullable: false),
                    User_IdUser = table.Column<Guid>(type: "uuid", nullable: false),
                    IsManager = table.Column<bool>(type: "boolean", nullable: false),
                    HasAdministrativePrivilege = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    UpdatedDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_OrganizationMembers", x => x.Id);
                    table.ForeignKey(
                        name: "FK_OrganizationMembers_Users_User_IdUser",
                        column: x => x.User_IdUser,
                        principalSchema: "public",
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Organizations",
                schema: "public",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    Status = table.Column<string>(type: "text", nullable: false),
                    OrganizationManager_IdOrganizationManager = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    UpdatedDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Organizations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Organizations_OrganizationMembers_OrganizationManager_IdOrg~",
                        column: x => x.OrganizationManager_IdOrganizationManager,
                        principalSchema: "public",
                        principalTable: "OrganizationMembers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Projects",
                schema: "public",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    Status = table.Column<string>(type: "text", nullable: false),
                    Organization_IdOrganization = table.Column<Guid>(type: "uuid", nullable: false),
                    ProjectManager_IdProjectManager = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    UpdatedDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Projects", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Projects_OrganizationMembers_ProjectManager_IdProjectManager",
                        column: x => x.ProjectManager_IdProjectManager,
                        principalSchema: "public",
                        principalTable: "OrganizationMembers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Projects_Organizations_Organization_IdOrganization",
                        column: x => x.Organization_IdOrganization,
                        principalSchema: "public",
                        principalTable: "Organizations",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ProjectPrivileges",
                schema: "public",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    Project_IdProject = table.Column<Guid>(type: "uuid", nullable: false),
                    OrganizationMember_IdOrganizationMember = table.Column<Guid>(type: "uuid", nullable: false),
                    Documents = table.Column<int>(type: "integer", nullable: false),
                    Meetings = table.Column<int>(type: "integer", nullable: false),
                    Settings = table.Column<int>(type: "integer", nullable: false),
                    Users = table.Column<int>(type: "integer", nullable: false),
                    CreatedDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    UpdatedDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ProjectPrivileges", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ProjectPrivileges_OrganizationMembers_OrganizationMember_Id~",
                        column: x => x.OrganizationMember_IdOrganizationMember,
                        principalSchema: "public",
                        principalTable: "OrganizationMembers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ProjectPrivileges_Projects_Project_IdProject",
                        column: x => x.Project_IdProject,
                        principalSchema: "public",
                        principalTable: "Projects",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ProjectRequirements",
                schema: "public",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    Project_IdProject = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "text", nullable: false),
                    Priority = table.Column<string>(type: "text", nullable: false),
                    Status = table.Column<string>(type: "text", nullable: false),
                    CreatedDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    UpdatedDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ProjectRequirements", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ProjectRequirements_Projects_Project_IdProject",
                        column: x => x.Project_IdProject,
                        principalSchema: "public",
                        principalTable: "Projects",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_OrganizationMembers_Organization_IdOrganization",
                schema: "public",
                table: "OrganizationMembers",
                column: "Organization_IdOrganization");

            migrationBuilder.CreateIndex(
                name: "IX_OrganizationMembers_User_IdUser",
                schema: "public",
                table: "OrganizationMembers",
                column: "User_IdUser",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Organizations_OrganizationManager_IdOrganizationManager",
                schema: "public",
                table: "Organizations",
                column: "OrganizationManager_IdOrganizationManager");

            migrationBuilder.CreateIndex(
                name: "IX_ProjectPrivileges_OrganizationMember_IdOrganizationMember",
                schema: "public",
                table: "ProjectPrivileges",
                column: "OrganizationMember_IdOrganizationMember");

            migrationBuilder.CreateIndex(
                name: "IX_ProjectPrivileges_Project_IdProject",
                schema: "public",
                table: "ProjectPrivileges",
                column: "Project_IdProject");

            migrationBuilder.CreateIndex(
                name: "IX_ProjectRequirements_Project_IdProject",
                schema: "public",
                table: "ProjectRequirements",
                column: "Project_IdProject");

            migrationBuilder.CreateIndex(
                name: "IX_Projects_Organization_IdOrganization",
                schema: "public",
                table: "Projects",
                column: "Organization_IdOrganization");

            migrationBuilder.CreateIndex(
                name: "IX_Projects_ProjectManager_IdProjectManager",
                schema: "public",
                table: "Projects",
                column: "ProjectManager_IdProjectManager");

            migrationBuilder.CreateIndex(
                name: "IX_Users_Country_IdCountry",
                schema: "public",
                table: "Users",
                column: "Country_IdCountry");

            migrationBuilder.AddForeignKey(
                name: "FK_OrganizationMembers_Organizations_Organization_IdOrganizati~",
                schema: "public",
                table: "OrganizationMembers",
                column: "Organization_IdOrganization",
                principalSchema: "public",
                principalTable: "Organizations",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_OrganizationMembers_Organizations_Organization_IdOrganizati~",
                schema: "public",
                table: "OrganizationMembers");

            migrationBuilder.DropTable(
                name: "ProjectPrivileges",
                schema: "public");

            migrationBuilder.DropTable(
                name: "ProjectRequirements",
                schema: "public");

            migrationBuilder.DropTable(
                name: "Projects",
                schema: "public");

            migrationBuilder.DropTable(
                name: "Organizations",
                schema: "public");

            migrationBuilder.DropTable(
                name: "OrganizationMembers",
                schema: "public");

            migrationBuilder.DropTable(
                name: "Users",
                schema: "public");

            migrationBuilder.DropTable(
                name: "Countries",
                schema: "public");
        }
    }
}
