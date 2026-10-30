using System.ComponentModel.DataAnnotations;

namespace FitLifeStudio.Models.Entities
{
    public enum Gender { Male, Female }
    public enum Goal { WeightLoss, Maintenance, MuscleGain }

    public class User
    {
        public int Id { get; set; }

        [Required, StringLength(50)]
        public string Username { get; set; } = string.Empty;

        [Required, EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        public string PasswordHash { get; set; } = string.Empty;

        [Range(12, 100)]
        public int Age { get; set; }

        [Range(30, 250)]
        public double WeightKg { get; set; }

        [Range(100, 250)]
        public double HeightCm { get; set; }

        public Gender Gender { get; set; }
        public Goal Goal { get; set; }

        public int RoleId { get; set; }
        public Role Role { get; set; } = null!;

        public ICollection<Subscription> Subscriptions { get; set; } = new List<Subscription>();
    }

    public class Role
    {
        public int Id { get; set; }

        [Required, StringLength(30)]
        public string RoleName { get; set; } = string.Empty;
    }
}