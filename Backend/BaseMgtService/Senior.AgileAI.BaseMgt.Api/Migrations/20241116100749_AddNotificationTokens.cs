using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Senior.AgileAI.BaseMgt.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddNotificationTokens : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
          

            migrationBuilder.DropForeignKey(
                name: "FK_notification_tokens_Users_User_IdUser",
                schema: "public",
                table: "notification_tokens");

            migrationBuilder.DropPrimaryKey(
                name: "PK_notification_tokens",
                schema: "public",
                table: "notification_tokens");

            migrationBuilder.RenameTable(
                name: "notification_tokens",
                schema: "public",
                newName: "NotificationTokens",
                newSchema: "public");

      

            migrationBuilder.RenameIndex(
                name: "IX_notification_tokens_User_IdUser",
                schema: "public",
                table: "NotificationTokens",
                newName: "IX_NotificationTokens_User_IdUser");

            migrationBuilder.AddPrimaryKey(
                name: "PK_NotificationTokens",
                schema: "public",
                table: "NotificationTokens",
                column: "Id");

 

            migrationBuilder.AddForeignKey(
                name: "FK_NotificationTokens_Users_User_IdUser",
                schema: "public",
                table: "NotificationTokens",
                column: "User_IdUser",
                principalSchema: "public",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
           
            migrationBuilder.DropForeignKey(
                name: "FK_NotificationTokens_Users_User_IdUser",
                schema: "public",
                table: "NotificationTokens");

            migrationBuilder.DropPrimaryKey(
                name: "PK_NotificationTokens",
                schema: "public",
                table: "NotificationTokens");

            migrationBuilder.RenameTable(
                name: "NotificationTokens",
                schema: "public",
                newName: "notification_tokens",
                newSchema: "public");

     

            migrationBuilder.RenameIndex(
                name: "IX_NotificationTokens_User_IdUser",
                schema: "public",
                table: "notification_tokens",
                newName: "IX_notification_tokens_User_IdUser");

            migrationBuilder.AddPrimaryKey(
                name: "PK_notification_tokens",
                schema: "public",
                table: "notification_tokens",
                column: "Id");

        

            migrationBuilder.AddForeignKey(
                name: "FK_notification_tokens_Users_User_IdUser",
                schema: "public",
                table: "notification_tokens",
                column: "User_IdUser",
                principalSchema: "public",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
