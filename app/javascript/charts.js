import {
  Chart,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  LineController,
  Title,
  Tooltip,
  Legend,
  ArcElement,
  DoughnutController,
  PieController
} from "chart.js";

Chart.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  LineController,
  Title,
  Tooltip,
  Legend,
  ArcElement,
  DoughnutController,
  PieController
);

document.addEventListener("turbo:load", () => {
  const dailyVisitsCanvas = document.getElementById("dailyVisitsChart");
  if (dailyVisitsCanvas) {
    const dailyVisitsData = JSON.parse(dailyVisitsCanvas.dataset.visits);
    // Convert hash to array of [date, count] if needed
    const dataArray = Array.isArray(dailyVisitsData) ? dailyVisitsData : Object.entries(dailyVisitsData);
    
    new Chart(dailyVisitsCanvas, {
      type: "line",
      data: {
        labels: dataArray.map((d) => d[0]),
        datasets: [
          {
            label: "Daily Visits",
            data: dataArray.map((d) => d[1]),
            borderColor: "rgb(75, 192, 192)",
            tension: 0.1,
          },
        ],
      },
      options: {
        responsive: true,
        plugins: {
          legend: {
            position: "top",
          },
          title: {
            display: true,
            text: "Daily Visits",
          },
        },
      },
    });
  }

  const trafficSourcesCanvas = document.getElementById("trafficSourcesChart");
  if (trafficSourcesCanvas) {
    const trafficSourcesData = JSON.parse(trafficSourcesCanvas.dataset.sources);
    new Chart(trafficSourcesCanvas, {
      type: "pie",
      data: {
        labels: trafficSourcesData.map((d) => d.name),
        datasets: [
          {
            data: trafficSourcesData.map((d) => d.visits),
            backgroundColor: trafficSourcesData.map((d) => d.color),
          },
        ],
      },
      options: {
        responsive: true,
        plugins: {
          legend: {
            position: "top",
          },
          title: {
            display: true,
            text: "Traffic Sources",
          },
        },
      },
    });
  }
});
