using System.ComponentModel.DataAnnotations;

namespace FitLifeStudio.Models.Entities
{
   

    public class Booking
    {
        public int Id { get; set; }
        public string UserId { get; set; } = string.Empty;

        public int GroupClassId { get; set; }
        public GroupClass GroupClass { get; set; } = null!;

        public string Status { get; set; } = "Confirmed"; // Confirmed, Cancelled
        public DateTime? CancelledAt { get; set; }
    }
}
