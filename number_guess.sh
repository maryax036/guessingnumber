#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"
secret_number=$(( RANDOM % 1000 + 1 ))

echo "Enter your username:"
read -r username

escaped_username=$(printf '%s' "$username" | sed "s/'/''/g")
user_info=$($PSQL "SELECT games_played || '|' || best_game FROM users WHERE username = '$escaped_username'")

if [[ -z $user_info ]]; then
	echo "Welcome, $username! It looks like this is your first time here."
else
	IFS='|' read -r games_played best_game <<< "$user_info"
	echo "Welcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
fi

echo "Guess the secret number between 1 and 1000:"
read -r guess

number_of_guesses=0
while true; do
	if [[ ! $guess =~ ^[+-]?[0-9]+$ ]]; then
		echo "That is not an integer, guess again:"
		read -r guess
		continue
	fi

	if [[ $guess == -* ]]; then
		guess_value=$((-10#${guess#-}))
	else
		guess_value=$((10#${guess#+}))
	fi
	((number_of_guesses += 1))

	if (( guess_value == secret_number )); then
		break
	elif (( guess_value > secret_number )); then
		echo "It's lower than that, guess again:"
	else
		echo "It's higher than that, guess again:"
	fi
	read -r guess
done

if [[ -z $user_info ]]; then
	$PSQL "INSERT INTO users (username, games_played, best_game) VALUES ('$escaped_username', 1, $number_of_guesses)" >/dev/null
else
	$PSQL "UPDATE users SET games_played = games_played + 1, best_game = CASE WHEN best_game IS NULL OR $number_of_guesses < best_game THEN $number_of_guesses ELSE best_game END WHERE username = '$escaped_username'" >/dev/null
fi

echo "You guessed it in $number_of_guesses tries. The secret number was $secret_number. Nice job!"
