package com.clockworkpc.burpata

import android.media.AudioAttributes
import android.media.SoundPool
import android.os.Bundle
import android.os.CountDownTimer
import android.view.WindowManager
import android.widget.TextView
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.content.ContextCompat

class WorkoutActivity : AppCompatActivity() {

    companion object {
        const val EXTRA_REPS_PER_SET = "reps_per_set"
        const val EXTRA_SECONDS_PER_SET = "seconds_per_set"
        const val EXTRA_NUMBER_OF_SETS = "number_of_sets"
        const val EXTRA_REST_BETWEEN_SETS = "rest_between_sets"
        const val COUNTDOWN_SECONDS = 3
    }

    private lateinit var rootLayout: ConstraintLayout
    private lateinit var statusText: TextView
    private lateinit var setCountText: TextView
    private lateinit var timerText: TextView
    private lateinit var repsText: TextView

    private lateinit var soundPool: SoundPool
    private var countdownSoundId: Int = 0
    private var whistleSoundId: Int = 0
    private var bellSoundId: Int = 0

    private var repsPerSet: Int = 0
    private var secondsPerSet: Int = 0
    private var numberOfSets: Int = 0
    private var restBetweenSets: Int = 0

    private var currentSet: Int = 1
    private var countDownTimer: CountDownTimer? = null
    private var workoutPhase: WorkoutPhase = WorkoutPhase.COUNTDOWN

    enum class WorkoutPhase {
        COUNTDOWN, ACTIVE_SET, REST
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_workout)

        // Keep screen on during workout
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        initializeViews()
        getWorkoutParameters()
        initializeSoundPool()
        startWorkout()
    }

    private fun initializeViews() {
        rootLayout = findViewById(R.id.rootLayout)
        statusText = findViewById(R.id.statusText)
        setCountText = findViewById(R.id.setCountText)
        timerText = findViewById(R.id.timerText)
        repsText = findViewById(R.id.repsText)
    }

    private fun getWorkoutParameters() {
        repsPerSet = intent.getIntExtra(EXTRA_REPS_PER_SET, 10)
        secondsPerSet = intent.getIntExtra(EXTRA_SECONDS_PER_SET, 20)
        numberOfSets = intent.getIntExtra(EXTRA_NUMBER_OF_SETS, 8)
        restBetweenSets = intent.getIntExtra(EXTRA_REST_BETWEEN_SETS, 10)
    }

    private fun initializeSoundPool() {
        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_GAME)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        soundPool = SoundPool.Builder()
            .setMaxStreams(3)
            .setAudioAttributes(audioAttributes)
            .build()

        // Load audio files
        countdownSoundId = soundPool.load(this, R.raw.countdown, 1)
        whistleSoundId = soundPool.load(this, R.raw.whistle, 1)
        bellSoundId = soundPool.load(this, R.raw.bell, 1)
    }

    private fun startWorkout() {
        updateSetCount()
        startCountdown()
    }

    private fun startCountdown() {
        workoutPhase = WorkoutPhase.COUNTDOWN
        statusText.text = getString(R.string.get_ready)
        repsText.text = "$repsPerSet ${getString(R.string.reps)}"
        setBackgroundColor(R.color.workout_countdown)

        countDownTimer = object : CountDownTimer((COUNTDOWN_SECONDS * 1000).toLong(), 1000) {
            override fun onTick(millisUntilFinished: Long) {
                val secondsRemaining = (millisUntilFinished / 1000).toInt() + 1
                timerText.text = secondsRemaining.toString()
                
                // Play countdown sound on each tick
                soundPool.play(countdownSoundId, 1.0f, 1.0f, 1, 0, 1.0f)
            }

            override fun onFinish() {
                startActiveSet()
            }
        }.start()
    }

    private fun startActiveSet() {
        workoutPhase = WorkoutPhase.ACTIVE_SET
        statusText.text = "${getString(R.string.set)} $currentSet"
        setBackgroundColor(R.color.workout_active)
        
        // Play whistle to start
        soundPool.play(whistleSoundId, 1.0f, 1.0f, 1, 0, 1.0f)

        countDownTimer = object : CountDownTimer((secondsPerSet * 1000).toLong(), 1000) {
            override fun onTick(millisUntilFinished: Long) {
                val secondsRemaining = (millisUntilFinished / 1000).toInt() + 1
                timerText.text = secondsRemaining.toString()
            }

            override fun onFinish() {
                // Play bell to end
                soundPool.play(bellSoundId, 1.0f, 1.0f, 1, 0, 1.0f)
                
                if (currentSet < numberOfSets) {
                    startRest()
                } else {
                    finishWorkout()
                }
            }
        }.start()
    }

    private fun startRest() {
        workoutPhase = WorkoutPhase.REST
        statusText.text = getString(R.string.rest)
        repsText.text = ""
        setBackgroundColor(R.color.workout_rest)

        countDownTimer = object : CountDownTimer((restBetweenSets * 1000).toLong(), 1000) {
            override fun onTick(millisUntilFinished: Long) {
                val secondsRemaining = (millisUntilFinished / 1000).toInt() + 1
                timerText.text = secondsRemaining.toString()
            }

            override fun onFinish() {
                currentSet++
                updateSetCount()
                startCountdown()
            }
        }.start()
    }

    private fun updateSetCount() {
        setCountText.text = "${getString(R.string.set)} $currentSet ${getString(R.string.of)} $numberOfSets"
    }

    private fun setBackgroundColor(colorResId: Int) {
        rootLayout.setBackgroundColor(ContextCompat.getColor(this, colorResId))
    }

    private fun finishWorkout() {
        AlertDialog.Builder(this)
            .setTitle(getString(R.string.workout_complete))
            .setMessage(getString(R.string.workout_successful))
            .setPositiveButton(getString(R.string.yes)) { dialog, _ ->
                dialog.dismiss()
                finish()
            }
            .setNegativeButton(getString(R.string.no)) { dialog, _ ->
                dialog.dismiss()
                finish()
            }
            .setCancelable(false)
            .show()
    }

    override fun onDestroy() {
        super.onDestroy()
        countDownTimer?.cancel()
        soundPool.release()
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    override fun onBackPressed() {
        AlertDialog.Builder(this)
            .setMessage("Are you sure you want to quit the workout?")
            .setPositiveButton("Yes") { dialog, _ ->
                dialog.dismiss()
                super.onBackPressed()
            }
            .setNegativeButton("No") { dialog, _ ->
                dialog.dismiss()
            }
            .show()
    }
}
