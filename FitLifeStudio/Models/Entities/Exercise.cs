using System.ComponentModel.DataAnnotations;

namespace FitLifeStudio.Models.Entities
{
    public class Exercise
    {
        public int Id { get; set; }

        [Required, StringLength(100)]
        public string Name { get; set; } = string.Empty;

        public string Description { get; set; } = string.Empty;
        public string MuscleGroup { get; set; } = string.Empty;

        public ICollection<WorkoutExercise> WorkoutExercises { get; set; } = new List<WorkoutExercise>();
    }
}
