
USE FitLifeStudioDb;
GO

/* 1. Създаване на процедура за резервации */

IF OBJECT_ID('dbo.CreateBooking', 'P') IS NOT NULL
    DROP PROCEDURE dbo.CreateBooking;
GO

CREATE PROCEDURE dbo.CreateBooking
    @UserId nvarchar(450),
    @GroupClassId int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @StartTime datetime2;
        DECLARE @EndTime datetime2;
        DECLARE @Capacity int;
        DECLARE @IsActive bit;

        SELECT
            @StartTime = StartTime,
            @EndTime = EndTime,
            @Capacity = Capacity,
            @IsActive = IsActive
        FROM dbo.GroupClasses WITH (UPDLOCK, HOLDLOCK)
        WHERE Id = @GroupClassId;

        IF @StartTime IS NULL OR @IsActive = 0
            THROW 50001, N'Тренировката не съществува или е неактивна.', 1;

        IF @StartTime <= SYSUTCDATETIME()
            THROW 50002, N'Тренировката вече е започнала.', 1;

        IF EXISTS (
            SELECT 1
            FROM dbo.Bookings
            WHERE UserId = @UserId
              AND GroupClassId = @GroupClassId
              AND Status = 'Confirmed'
        )
            THROW 50003, N'Вече имате резервация за този час.', 1;

        IF (
            SELECT COUNT(*)
            FROM dbo.Bookings WITH (UPDLOCK, HOLDLOCK)
            WHERE GroupClassId = @GroupClassId
              AND Status = 'Confirmed'
        ) >= @Capacity
            THROW 50004, N'Няма свободни места.', 1;

        IF EXISTS (
            SELECT 1
            FROM dbo.Bookings b
            INNER JOIN dbo.GroupClasses g
                ON g.Id = b.GroupClassId
            WHERE b.UserId = @UserId
              AND b.Status = 'Confirmed'
              AND g.StartTime < @EndTime
              AND g.EndTime > @StartTime
        )
            THROW 50005, N'Имате друга тренировка по същото време.', 1;

        INSERT INTO dbo.Bookings
            (UserId, GroupClassId, Status)
        VALUES
            (@UserId, @GroupClassId, 'Confirmed');

        DECLARE @BookingId int = CAST(SCOPE_IDENTITY() AS int);

        COMMIT TRANSACTION;

        SELECT @BookingId AS BookingId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

/* 2. Отказване на резервация */

IF OBJECT_ID('dbo.CancelBooking', 'P') IS NOT NULL
    DROP PROCEDURE dbo.CancelBooking;
GO

CREATE PROCEDURE dbo.CancelBooking
    @BookingId int,
    @UserId nvarchar(450)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @StartTime datetime2;
        DECLARE @Status nvarchar(20);

        SELECT
            @StartTime = g.StartTime,
            @Status = b.Status
        FROM dbo.Bookings b WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN dbo.GroupClasses g
            ON g.Id = b.GroupClassId
        WHERE b.Id = @BookingId
          AND b.UserId = @UserId;

        IF @StartTime IS NULL
            THROW 50011, N'Резервацията не е намерена.', 1;

        IF @Status <> 'Confirmed'
            THROW 50012, N'Резервацията не е активна.', 1;

        IF @StartTime <= DATEADD(HOUR, 2, SYSUTCDATETIME())
            THROW 50013, N'Отказването е разрешено до 2 часа преди началото.', 1;

        UPDATE dbo.Bookings
        SET Status = 'Cancelled',
            CancelledAt = SYSUTCDATETIME()
        WHERE Id = @BookingId
          AND UserId = @UserId;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

/* 3. Деактивиране на тренировъчна програма */

IF OBJECT_ID('dbo.DeactivateWorkoutPlan', 'P') IS NOT NULL
    DROP PROCEDURE dbo.DeactivateWorkoutPlan;
GO

CREATE PROCEDURE dbo.DeactivateWorkoutPlan
    @WorkoutPlanId int
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.WorkoutPlans
        WHERE Id = @WorkoutPlanId
    )
        THROW 50021, N'Програмата не е намерена.', 1;

    IF EXISTS (
        SELECT 1
        FROM dbo.WorkoutPlans
        WHERE Id = @WorkoutPlanId
          AND IsActive = 1
          AND ClientId IS NOT NULL
    )
        THROW 50022, N'Програмата е активна за клиент и не може да се деактивира.', 1;

    UPDATE dbo.WorkoutPlans
    SET IsActive = 0
    WHERE Id = @WorkoutPlanId
      AND IsActive = 1;

    IF @@ROWCOUNT = 0
        THROW 50023, N'Програмата вече е неактивна.', 1;
END;
GO

/* 4. Проверка дали трите процедури са създадени */

SELECT name
FROM sys.procedures
WHERE name IN (
    'CreateBooking',
    'CancelBooking',
    'DeactivateWorkoutPlan'
);
GO

USE FitLifeStudioDb;
GO

SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;