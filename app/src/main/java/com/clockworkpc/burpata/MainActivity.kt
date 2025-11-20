package com.clockworkpc.burpata

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.textfield.TextInputEditText
import com.google.android.material.button.MaterialButton

class MainActivity : AppCompatActivity() {

    private lateinit var repsPerSetInput: TextInputEditText
    private lateinit var secondsPerSetInput: TextInputEditText
    private lateinit var numberOfSetsInput: TextInputEditText
    private lateinit var restBetweenSetsInput: TextInputEditText
    private lateinit var startWorkoutButton: MaterialButton

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        initializeViews()
        setupListeners()
    }

    private fun initializeViews() {
        repsPerSetInput = findViewById(R.id.repsPerSetInput)
        secondsPerSetInput = findViewById(R.id.secondsPerSetInput)
        numberOfSetsInput = findViewById(R.id.numberOfSetsInput)
        restBetweenSetsInput = findViewById(R.id.restBetweenSetsInput)
        startWorkoutButton = findViewById(R.id.startWorkoutButton)
    }

    private fun setupListeners() {
        startWorkoutButton.setOnClickListener {
            if (validateInputs()) {
                startWorkout()
            }
        }
    }

    private fun validateInputs(): Boolean {
        val repsPerSet = repsPerSetInput.text.toString().toIntOrNull()
        val secondsPerSet = secondsPerSetInput.text.toString().toIntOrNull()
        val numberOfSets = numberOfSetsInput.text.toString().toIntOrNull()
        val restBetweenSets = restBetweenSetsInput.text.toString().toIntOrNull()

        when {
            repsPerSet == null || repsPerSet <= 0 -> {
                Toast.makeText(this, "Please enter valid reps per set", Toast.LENGTH_SHORT).show()
                return false
            }
            secondsPerSet == null || secondsPerSet <= 0 -> {
                Toast.makeText(this, "Please enter valid seconds per set", Toast.LENGTH_SHORT).show()
                return false
            }
            numberOfSets == null || numberOfSets <= 0 -> {
                Toast.makeText(this, "Please enter valid number of sets", Toast.LENGTH_SHORT).show()
                return false
            }
            restBetweenSets == null || restBetweenSets < 0 -> {
                Toast.makeText(this, "Please enter valid rest time", Toast.LENGTH_SHORT).show()
                return false
            }
        }

        return true
    }

    private fun startWorkout() {
        val intent = Intent(this, WorkoutActivity::class.java).apply {
            putExtra(WorkoutActivity.EXTRA_REPS_PER_SET, repsPerSetInput.text.toString().toInt())
            putExtra(WorkoutActivity.EXTRA_SECONDS_PER_SET, secondsPerSetInput.text.toString().toInt())
            putExtra(WorkoutActivity.EXTRA_NUMBER_OF_SETS, numberOfSetsInput.text.toString().toInt())
            putExtra(WorkoutActivity.EXTRA_REST_BETWEEN_SETS, restBetweenSetsInput.text.toString().toInt())
        }
        startActivity(intent)
    }
}
