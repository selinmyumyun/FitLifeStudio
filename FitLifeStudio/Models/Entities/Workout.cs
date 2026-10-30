using System.ComponentModel.DataAnnotations;

namespace FitLifeStudio.Models.Entities
{
    public class Workout
    {
        public int Id { get; set; }

        [Required, StringLength(100)]
        public string Title { get; set; } = string.Empty;

        public string Description { get; set; } = string.Empty;
        public string DifficultyLevel { get; set; } = "Beginner";
        public string TargetMuscleGroup { get; set; } = string.Empty;
        public int DurationMinutes { get; set; }
        public bool IsPremium { get; set; }

        public ICollection<WorkoutExercise> WorkoutExercises { get; set; } = new List<WorkoutExercise>();
    }
}