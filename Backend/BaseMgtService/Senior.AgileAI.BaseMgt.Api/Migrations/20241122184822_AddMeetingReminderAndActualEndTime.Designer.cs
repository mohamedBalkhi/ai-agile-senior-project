﻿// <auto-generated />
using System;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;
using Senior.AgileAI.BaseMgt.Infrastructure.Data;

#nullable disable

namespace Senior.AgileAI.BaseMgt.Api.Migrations
{
    [DbContext(typeof(PostgreSqlAppDbContext))]
    [Migration("20241122184822_AddMeetingReminderAndActualEndTime")]
    partial class AddMeetingReminderAndActualEndTime
    {
        /// <inheritdoc />
        protected override void BuildTargetModel(ModelBuilder modelBuilder)
        {
#pragma warning disable 612, 618
            modelBuilder
                .HasDefaultSchema("public")
                .HasAnnotation("ProductVersion", "8.0.10")
                .HasAnnotation("Relational:MaxIdentifierLength", 63);

            NpgsqlModelBuilderExtensions.UseIdentityByDefaultColumns(modelBuilder);

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.Country", b =>
                {
                    b.Property<Guid>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("uuid")
                        .HasDefaultValueSql("gen_random_uuid()");

                    b.Property<string>("Code")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<DateTime>("CreatedDate")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("timestamp without time zone")
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");

                    b.Property<bool>("IsActive")
                        .HasColumnType("boolean");

                    b.Property<string>("Name")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<DateTime>("UpdatedDate")
                        .ValueGeneratedOnAddOrUpdate()
                        .HasColumnType("timestamp without time zone")
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");

                    b.HasKey("Id");

                    b.ToTable("Countries", "public");
                });

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.Meeting", b =>
                {
                    b.Property<Guid>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("uuid")
                        .HasDefaultValueSql("gen_random_uuid()");

                    b.Property<DateTime?>("ActualEndTime")
                        .HasColumnType("timestamp with time zone");

                    b.Property<int>("AudioSource")
                        .HasColumnType("integer");

                    b.Property<int>("AudioStatus")
                        .HasColumnType("integer");

                    b.Property<DateTime?>("AudioUploadedAt")
                        .HasColumnType("timestamp with time zone");

                    b.Property<string>("AudioUrl")
                        .HasMaxLength(1000)
                        .HasColumnType("character varying(1000)");

                    b.Property<DateTime>("CreatedDate")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("timestamp without time zone")
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");

                    b.Property<Guid>("Creator_IdOrganizationMember")
                        .HasColumnType("uuid");

                    b.Property<DateTime>("EndTime")
                        .HasColumnType("timestamp with time zone");

                    b.Property<string>("Goal")
                        .IsRequired()
                        .HasMaxLength(1000)
                        .HasColumnType("character varying(1000)");

                    b.Property<int>("Language")
                        .HasColumnType("integer");

                    b.Property<string>("Location")
                        .HasMaxLength(500)
                        .HasColumnType("character varying(500)");

                    b.Property<string>("MeetingUrl")
                        .HasColumnType("text");

                    b.Property<Guid>("Project_IdProject")
                        .HasColumnType("uuid");

                    b.Property<Guid?>("RecurringPattern_IdRecurringPattern")
                        .HasColumnType("uuid");

                    b.Property<bool>("ReminderSent")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("boolean")
                        .HasDefaultValue(false);

                    b.Property<DateTime?>("ReminderTime")
                        .IsRequired()
                        .HasColumnType("timestamp with time zone");

                    b.Property<DateTime>("StartTime")
                        .HasColumnType("timestamp with time zone");

                    b.Property<int>("Status")
                        .HasColumnType("integer");

                    b.Property<string>("TimeZoneId")
                        .IsRequired()
                        .HasMaxLength(100)
                        .HasColumnType("character varying(100)");

                    b.Property<string>("Title")
                        .IsRequired()
                        .HasMaxLength(200)
                        .HasColumnType("character varying(200)");

                    b.Property<int>("Type")
                        .HasColumnType("integer");

                    b.Property<DateTime>("UpdatedDate")
                        .ValueGeneratedOnAddOrUpdate()
                        .HasColumnType("timestamp without time zone")
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");

                    b.HasKey("Id");

                    b.HasIndex("Creator_IdOrganizationMember");

                    b.HasIndex("Project_IdProject");

                    b.HasIndex("RecurringPattern_IdRecurringPattern")
                        .IsUnique();

                    b.HasIndex("StartTime");

                    b.HasIndex("Status");

                    b.ToTable("Meetings", "public");
                });

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.MeetingMember", b =>
                {
                    b.Property<Guid>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("uuid")
                        .HasDefaultValueSql("gen_random_uuid()");

                    b.Property<DateTime>("CreatedDate")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("timestamp without time zone")
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");

                    b.Property<bool>("HasConfirmed")
                        .HasColumnType("boolean");

                    b.Property<Guid>("Meeting_IdMeeting")
                        .HasColumnType("uuid");

                    b.Property<Guid>("OrganizationMember_IdOrganizationMember")
                        .HasColumnType("uuid");

                    b.Property<DateTime>("UpdatedDate")
                        .ValueGeneratedOnAddOrUpdate()
                        .HasColumnType("timestamp without time zone")
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");

                    b.HasKey("Id");

                    b.HasIndex("Meeting_IdMeeting");

                    b.HasIndex("OrganizationMember_IdOrganizationMember");

                    b.HasIndex("Meeting_IdMeeting", "OrganizationMember_IdOrganizationMember")
                        .IsUnique();

                    b.ToTable("MeetingMembers", "public");
                });

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.NotificationToken", b =>
                {
                    b.Property<Guid>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("uuid")
                        .HasDefaultValueSql("gen_random_uuid()");

                    b.Property<DateTime>("CreatedDate")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("timestamp without time zone")
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");

                    b.Property<string>("DeviceId")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<string>("Token")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<DateTime>("UpdatedDate")
                        .ValueGeneratedOnAddOrUpdate()
                        .HasColumnType("timestamp without time zone")
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");

                    b.Property<Guid>("User_IdUser")
                        .HasColumnType("uuid");

                    b.HasKey("Id");

                    b.HasIndex("User_IdUser");

                    b.ToTable("NotificationTokens", "public");
                });

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.Organization", b =>
                {
                    b.Property<Guid>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("uuid")
                        .HasDefaultValueSql("gen_random_uuid()");

                    b.Property<DateTime>("CreatedDate")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("timestamp without time zone")
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");

                    b.Property<string>("Description")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<bool>("IsActive")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("boolean")
                        .HasDefaultValue(true)
                        .HasColumnName("IsActive");

                    b.Property<string>("Logo")
                        .HasColumnType("text");

                    b.Property<string>("Name")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<Guid?>("OrganizationManager_IdOrganizationManager")
                        .HasColumnType("uuid");

                    b.Property<string>("Status")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<DateTime>("UpdatedDate")
                        .ValueGeneratedOnAddOrUpdate()
                        .HasColumnType("timestamp without time zone")
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");

                    b.HasKey("Id");

                    b.HasIndex("OrganizationManager_IdOrganizationManager")
                        .IsUnique();

                    b.ToTable("Organizations", "public");
                });

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.OrganizationMember", b =>
                {
                    b.Property<Guid>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("uuid")
                        .HasDefaultValueSql("gen_random_uuid()");

                    b.Property<DateTime>("CreatedDate")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("timestamp without time zone")
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");

                    b.Property<bool>("HasAdministrativePrivilege")
                        .HasColumnType("boolean");

                    b.Property<bool>("IsManager")
                        .HasColumnType("boolean");

                    b.Property<Guid>("Organization_IdOrganization")
                        .HasColumnType("uuid");

                    b.Property<DateTime>("UpdatedDate")
                        .ValueGeneratedOnAddOrUpdate()
                        .HasColumnType("timestamp without time zone")
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");

                    b.Property<Guid>("User_IdUser")
                        .HasColumnType("uuid");

                    b.HasKey("Id");

                    b.HasIndex("Organization_IdOrganization");

                    b.HasIndex("User_IdUser")
                        .IsUnique();

                    b.ToTable("OrganizationMembers", "public");
                });

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.Project", b =>
                {
                    b.Property<Guid>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("uuid")
                        .HasDefaultValueSql("gen_random_uuid()");

                    b.Property<DateTime>("CreatedDate")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("timestamp without time zone")
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");

                    b.Property<string>("Description")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<string>("Name")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<Guid>("Organization_IdOrganization")
                        .HasColumnType("uuid");

                    b.Property<Guid>("ProjectManager_IdProjectManager")
                        .HasColumnType("uuid");

                    b.Property<bool>("Status")
                        .HasColumnType("boolean");

                    b.Property<DateTime>("UpdatedDate")
                        .ValueGeneratedOnAddOrUpdate()
                        .HasColumnType("timestamp without time zone")
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");

                    b.HasKey("Id");

                    b.HasIndex("Organization_IdOrganization");

                    b.HasIndex("ProjectManager_IdProjectManager");

                    b.ToTable("Projects", "public");
                });

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.ProjectPrivilege", b =>
                {
                    b.Property<Guid>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("uuid")
                        .HasDefaultValueSql("gen_random_uuid()");

                    b.Property<DateTime>("CreatedDate")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("timestamp without time zone")
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");

                    b.Property<int>("Meetings")
                        .HasColumnType("integer");

                    b.Property<int>("Members")
                        .HasColumnType("integer");

                    b.Property<Guid>("OrganizationMember_IdOrganizationMember")
                        .HasColumnType("uuid");

                    b.Property<Guid>("Project_IdProject")
                        .HasColumnType("uuid");

                    b.Property<int>("Requirements")
                        .HasColumnType("integer");

                    b.Property<int>("Settings")
                        .HasColumnType("integer");

                    b.Property<int>("Tasks")
                        .HasColumnType("integer");

                    b.Property<DateTime>("UpdatedDate")
                        .ValueGeneratedOnAddOrUpdate()
                        .HasColumnType("timestamp without time zone")
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");

                    b.HasKey("Id");

                    b.HasIndex("OrganizationMember_IdOrganizationMember");

                    b.HasIndex("Project_IdProject");

                    b.ToTable("ProjectPrivileges", "public");
                });

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.ProjectRequirement", b =>
                {
                    b.Property<Guid>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("uuid")
                        .HasDefaultValueSql("gen_random_uuid()");

                    b.Property<DateTime>("CreatedDate")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("timestamp without time zone")
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");

                    b.Property<string>("Description")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<string>("Priority")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<Guid>("Project_IdProject")
                        .HasColumnType("uuid");

                    b.Property<string>("Status")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<string>("Title")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<DateTime>("UpdatedDate")
                        .ValueGeneratedOnAddOrUpdate()
                        .HasColumnType("timestamp without time zone")
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");

                    b.HasKey("Id");

                    b.HasIndex("Project_IdProject");

                    b.ToTable("ProjectRequirements", "public");
                });

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.RecurringMeetingException", b =>
                {
                    b.Property<Guid>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("uuid")
                        .HasDefaultValueSql("gen_random_uuid()");

                    b.Property<DateTime>("CreatedDate")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("timestamp without time zone")
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");

                    b.Property<DateTime>("ExceptionDate")
                        .HasColumnType("timestamp with time zone");

                    b.Property<string>("Reason")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<Guid>("RecurringPattern_IdRecurringPattern")
                        .HasColumnType("uuid");

                    b.Property<DateTime>("UpdatedDate")
                        .ValueGeneratedOnAddOrUpdate()
                        .HasColumnType("timestamp without time zone")
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");

                    b.HasKey("Id");

                    b.HasIndex("ExceptionDate");

                    b.HasIndex("RecurringPattern_IdRecurringPattern");

                    b.HasIndex("RecurringPattern_IdRecurringPattern", "ExceptionDate")
                        .HasDatabaseName("IX_RecurringMeetingExceptions_RecurringPattern_IdRecurringPat~1");

                    b.ToTable("RecurringMeetingExceptions", "public");
                });

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.RecurringMeetingPattern", b =>
                {
                    b.Property<Guid>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("uuid")
                        .HasDefaultValueSql("gen_random_uuid()");

                    b.Property<DateTime>("CreatedDate")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("timestamp without time zone")
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");

                    b.Property<int?>("DaysOfWeek")
                        .HasColumnType("integer");

                    b.Property<int>("Interval")
                        .HasColumnType("integer");

                    b.Property<Guid>("Meeting_IdMeeting")
                        .HasColumnType("uuid");

                    b.Property<int>("RecurrenceType")
                        .HasColumnType("integer");

                    b.Property<DateTime>("RecurringEndDate")
                        .HasColumnType("timestamp with time zone");

                    b.Property<DateTime>("UpdatedDate")
                        .ValueGeneratedOnAddOrUpdate()
                        .HasColumnType("timestamp without time zone")
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");

                    b.HasKey("Id");

                    b.HasIndex("Meeting_IdMeeting")
                        .IsUnique();

                    b.HasIndex("RecurringEndDate");

                    b.ToTable("RecurringMeetingPatterns", "public");
                });

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.RefreshToken", b =>
                {
                    b.Property<Guid>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("uuid")
                        .HasDefaultValueSql("gen_random_uuid()");

                    b.Property<DateTime>("CreatedDate")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("timestamp without time zone")
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");

                    b.Property<string>("Token")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<DateTime>("UpdatedDate")
                        .ValueGeneratedOnAddOrUpdate()
                        .HasColumnType("timestamp without time zone")
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");

                    b.Property<Guid>("User_IdUser")
                        .HasColumnType("uuid");

                    b.HasKey("Id");

                    b.HasIndex("Token")
                        .IsUnique();

                    b.HasIndex("User_IdUser");

                    b.HasIndex("User_IdUser", "Token");

                    b.ToTable("RefreshTokens", "public");
                });

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.User", b =>
                {
                    b.Property<Guid>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("uuid")
                        .HasDefaultValueSql("gen_random_uuid()");

                    b.Property<DateTime>("BirthDate")
                        .HasColumnType("timestamp without time zone");

                    b.Property<string>("Code")
                        .HasColumnType("text");

                    b.Property<Guid>("Country_IdCountry")
                        .HasColumnType("uuid");

                    b.Property<DateTime>("CreatedDate")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("timestamp without time zone")
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");

                    b.Property<bool>("Deactivated")
                        .HasColumnType("boolean");

                    b.Property<string>("Email")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<string>("FUllName")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<bool>("IsActive")
                        .HasColumnType("boolean");

                    b.Property<bool>("IsAdmin")
                        .HasColumnType("boolean");

                    b.Property<bool>("IsTrusted")
                        .HasColumnType("boolean");

                    b.Property<string>("Password")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<DateTime>("UpdatedDate")
                        .ValueGeneratedOnAddOrUpdate()
                        .HasColumnType("timestamp without time zone")
                        .HasDefaultValueSql("CURRENT_TIMESTAMP");

                    b.HasKey("Id");

                    b.HasIndex("Country_IdCountry");

                    b.HasIndex("Email")
                        .IsUnique();

                    b.ToTable("Users", "public");
                });

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.Meeting", b =>
                {
                    b.HasOne("Senior.AgileAI.BaseMgt.Domain.Entities.OrganizationMember", "Creator")
                        .WithMany()
                        .HasForeignKey("Creator_IdOrganizationMember")
                        .OnDelete(DeleteBehavior.Restrict)
                        .IsRequired();

                    b.HasOne("Senior.AgileAI.BaseMgt.Domain.Entities.Project", "Project")
                        .WithMany()
                        .HasForeignKey("Project_IdProject")
                        .OnDelete(DeleteBehavior.Restrict)
                        .IsRequired();

                    b.Navigation("Creator");

                    b.Navigation("Project");
                });

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.MeetingMember", b =>
                {
                    b.HasOne("Senior.AgileAI.BaseMgt.Domain.Entities.Meeting", "Meeting")
                        .WithMany("MeetingMembers")
                        .HasForeignKey("Meeting_IdMeeting")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.HasOne("Senior.AgileAI.BaseMgt.Domain.Entities.OrganizationMember", "OrganizationMember")
                        .WithMany()
                        .HasForeignKey("OrganizationMember_IdOrganizationMember")
                        .OnDelete(DeleteBehavior.Restrict)
                        .IsRequired();

                    b.Navigation("Meeting");

                    b.Navigation("OrganizationMember");
                });

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.NotificationToken", b =>
                {
                    b.HasOne("Senior.AgileAI.BaseMgt.Domain.Entities.User", "User")
                        .WithMany("NotificationTokens")
                        .HasForeignKey("User_IdUser")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.Navigation("User");
                });

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.Organization", b =>
                {
                    b.HasOne("Senior.AgileAI.BaseMgt.Domain.Entities.User", "OrganizationManager")
                        .WithOne("Organization")
                        .HasForeignKey("Senior.AgileAI.BaseMgt.Domain.Entities.Organization", "OrganizationManager_IdOrganizationManager")
                        .OnDelete(DeleteBehavior.Cascade);

                    b.Navigation("OrganizationManager");
                });

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.OrganizationMember", b =>
                {
                    b.HasOne("Senior.AgileAI.BaseMgt.Domain.Entities.Organization", "Organization")
                        .WithMany("OrganizationMembers")
                        .HasForeignKey("Organization_IdOrganization")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.HasOne("Senior.AgileAI.BaseMgt.Domain.Entities.User", "User")
                        .WithOne("OrganizationMember")
                        .HasForeignKey("Senior.AgileAI.BaseMgt.Domain.Entities.OrganizationMember", "User_IdUser")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.Navigation("Organization");

                    b.Navigation("User");
                });

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.Project", b =>
                {
                    b.HasOne("Senior.AgileAI.BaseMgt.Domain.Entities.Organization", "Organization")
                        .WithMany("Projects")
                        .HasForeignKey("Organization_IdOrganization")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.HasOne("Senior.AgileAI.BaseMgt.Domain.Entities.OrganizationMember", "ProjectManager")
                        .WithMany()
                        .HasForeignKey("ProjectManager_IdProjectManager")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.Navigation("Organization");

                    b.Navigation("ProjectManager");
                });

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.ProjectPrivilege", b =>
                {
                    b.HasOne("Senior.AgileAI.BaseMgt.Domain.Entities.OrganizationMember", "OrganizationMember")
                        .WithMany("ProjectPrivileges")
                        .HasForeignKey("OrganizationMember_IdOrganizationMember")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.HasOne("Senior.AgileAI.BaseMgt.Domain.Entities.Project", "Project")
                        .WithMany("ProjectPrivileges")
                        .HasForeignKey("Project_IdProject")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.Navigation("OrganizationMember");

                    b.Navigation("Project");
                });

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.ProjectRequirement", b =>
                {
                    b.HasOne("Senior.AgileAI.BaseMgt.Domain.Entities.Project", "Project")
                        .WithMany("ProjectRequirements")
                        .HasForeignKey("Project_IdProject")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.Navigation("Project");
                });

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.RecurringMeetingException", b =>
                {
                    b.HasOne("Senior.AgileAI.BaseMgt.Domain.Entities.RecurringMeetingPattern", "RecurringPattern")
                        .WithMany()
                        .HasForeignKey("RecurringPattern_IdRecurringPattern")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.Navigation("RecurringPattern");
                });

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.RecurringMeetingPattern", b =>
                {
                    b.HasOne("Senior.AgileAI.BaseMgt.Domain.Entities.Meeting", "Meeting")
                        .WithOne("RecurringPattern")
                        .HasForeignKey("Senior.AgileAI.BaseMgt.Domain.Entities.RecurringMeetingPattern", "Meeting_IdMeeting")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.Navigation("Meeting");
                });

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.RefreshToken", b =>
                {
                    b.HasOne("Senior.AgileAI.BaseMgt.Domain.Entities.User", "User")
                        .WithMany("RefreshTokens")
                        .HasForeignKey("User_IdUser")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.Navigation("User");
                });

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.User", b =>
                {
                    b.HasOne("Senior.AgileAI.BaseMgt.Domain.Entities.Country", "Country")
                        .WithMany("Users")
                        .HasForeignKey("Country_IdCountry")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.Navigation("Country");
                });

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.Country", b =>
                {
                    b.Navigation("Users");
                });

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.Meeting", b =>
                {
                    b.Navigation("MeetingMembers");

                    b.Navigation("RecurringPattern");
                });

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.Organization", b =>
                {
                    b.Navigation("OrganizationMembers");

                    b.Navigation("Projects");
                });

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.OrganizationMember", b =>
                {
                    b.Navigation("ProjectPrivileges");
                });

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.Project", b =>
                {
                    b.Navigation("ProjectPrivileges");

                    b.Navigation("ProjectRequirements");
                });

            modelBuilder.Entity("Senior.AgileAI.BaseMgt.Domain.Entities.User", b =>
                {
                    b.Navigation("NotificationTokens");

                    b.Navigation("Organization");

                    b.Navigation("OrganizationMember");

                    b.Navigation("RefreshTokens");
                });
#pragma warning restore 612, 618
        }
    }
}
