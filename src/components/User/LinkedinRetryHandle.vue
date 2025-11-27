<template>
  <div class="linkedin-retry-container">
    <div class="retry-card">
      <!-- LinkedIn icon -->
      <div class="icon-container">
        <div class="icon">
          <svg viewBox="0 0 24 24" class="linkedin-icon">
            <path
              d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"
            />
          </svg>
        </div>
      </div>

      <!-- Title -->
      <h1 class="title">Authenticating with LinkedIn</h1>

      <!-- Loading message with spinner -->
      <div class="message-box">
        <div class="spinner"></div>
        <span>Connecting to LinkedIn...</span>
      </div>

      <!-- Progress indicator -->
      <div class="progress-container">
        <div class="progress-bar" :style="{ width: progressWidth + '%' }"></div>
      </div>

      <!-- Countdown display -->
      <div class="countdown-text">Retrying in {{ countdown }} seconds...</div>

      <!-- Cancel button -->
      <router-link to="/login" class="cancel-button">
        Cancel and return to login
      </router-link>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from "vue";
import { useRoute } from "vue-router";

const route = useRoute();

// Reactive state
const countdown = ref(0);
const progressWidth = ref(0);
const totalTime = ref(0);

// Timer reference
let timer: NodeJS.Timeout | null = null;

// Get parameters from URL
const provider = route.query.provider as string;
const attempt = parseInt(route.query.attempt as string) || 1;
const delay = parseInt(route.query.delay as string) || 2;
const token = route.query.token as string;
const error = route.query.error as string;

onMounted(() => {
  console.log("LinkedIn retry handler mounted:", {
    provider,
    attempt,
    delay,
    token: token?.substring(0, 20) + "...",
    error,
  });

  // Initialize countdown
  countdown.value = delay;
  totalTime.value = delay;
  progressWidth.value = 0;

  // Start countdown timer
  timer = setInterval(() => {
    countdown.value--;
    progressWidth.value =
      ((totalTime.value - countdown.value) / totalTime.value) * 100;

    if (countdown.value <= 0) {
      clearInterval(timer!);
      progressWidth.value = 100;

      // Redirect to retry endpoint after countdown
      setTimeout(() => {
        window.location.href = `/auth/retry/${provider}?token=${token}`;
      }, 500);
    }
  }, 1000);
});

onUnmounted(() => {
  if (timer) {
    clearInterval(timer);
  }
});

// Handle visibility change (pause timer when tab is hidden)
const handleVisibilityChange = () => {
  if (document.hidden && timer) {
    clearInterval(timer);
  }
};

onMounted(() => {
  document.addEventListener("visibilitychange", handleVisibilityChange);
});

onUnmounted(() => {
  document.removeEventListener("visibilitychange", handleVisibilityChange);
});
</script>

<style scoped>
.linkedin-retry-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1rem;
  background-color: #f9fafb;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
}

.retry-card {
  width: 100%;
  max-width: 28rem;
  background: white;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  border: 1px solid #e5e7eb;
  border-radius: 0.5rem;
  padding: 3rem 1.5rem;
  text-align: center;
}

.icon-container {
  margin-bottom: 1.5rem;
}

.icon {
  width: 3rem;
  height: 3rem;
  margin: 0 auto;
  background-color: #2563eb;
  border-radius: 0.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
}

.linkedin-icon {
  width: 1.5rem;
  height: 1.5rem;
  fill: white;
}

.title {
  font-size: 1.5rem;
  font-weight: bold;
  color: #111827;
  margin-bottom: 1.5rem;
  margin-top: 0;
}

.message-box {
  background-color: #fef3c7;
  border: 1px solid #fbbf24;
  border-radius: 0.25rem;
  color: #92400e;
  padding: 0.75rem 1rem;
  font-size: 0.875rem;
  margin-bottom: 1.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
}

.spinner {
  width: 1rem;
  height: 1rem;
  border: 2px solid #92400e;
  border-top: 2px solid transparent;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-right: 0.5rem;
}

@keyframes spin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}

.progress-container {
  width: 100%;
  height: 0.5rem;
  background-color: #e5e7eb;
  border-radius: 0.25rem;
  margin-bottom: 1.5rem;
  overflow: hidden;
}

.progress-bar {
  height: 100%;
  background-color: #2563eb;
  border-radius: 0.25rem;
  transition: width 0.3s ease;
}

.countdown-text {
  font-size: 0.875rem;
  color: #6b7280;
  margin-bottom: 1.5rem;
}

.cancel-button {
  font-size: 0.875rem;
  background-color: #4b5563;
  color: white;
  padding: 0.5rem 0.75rem;
  text-decoration: none;
  display: inline-block;
  transition: background-color 0.2s;
  border-radius: 0.25rem;
}

.cancel-button:hover {
  background-color: #374151;
}

@media (max-width: 768px) {
  .retry-card {
    padding: 2rem 1rem;
  }

  .title {
    font-size: 1.25rem;
  }
}
</style>
