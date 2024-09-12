#! /bin/bash
PSQL="psql --username=postgres --dbname=salon -t --no-align -c"

echo -e "\n~~~~~ Welcome to LUNA salon! ~~~~~~"

MAIN_MENU() {

  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi

  SERVICES_LIST=$($PSQL "SELECT service_id, name FROM services")

  echo -e "\nPlease choose one of the options below:"
  
  echo "$SERVICES_LIST" | while IFS="|" read SERVICE_ID SERVICE_NAME
  do
    echo "$SERVICE_ID) $SERVICE_NAME"
  done

  # Get the last service_id
  LAST_SERVICE_ID=$(echo "$SERVICES_LIST" | tail -n 1 | cut -d'|' -f1)

  # Add 1 to the last service ID to create an EXIT_ID
  EXIT_ID=$((LAST_SERVICE_ID + 1))
  
  # Add the exit option at the end
  echo "$EXIT_ID) Exit"
  read SERVICE_ID_SELECTED

  # Case statement to handle menu selection
  if [[ $SERVICE_ID_SELECTED -ge 1 && $SERVICE_ID_SELECTED -le $LAST_SERVICE_ID ]]
  then
    APPOINTMENT_MENU
  elif [[ $SERVICE_ID_SELECTED -eq $EXIT_ID ]]
  then
    EXIT
  else
    MAIN_MENU "Please enter a valid option."
  fi
}

APPOINTMENT_MENU() {
  echo -e "\nWhat's your phone number?"
  read CUSTOMER_PHONE

  # Get customer ID
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
  
  # If the customer does not exist, insert the new customer
  if [[ -z $CUSTOMER_ID ]]
  then
    echo -e "\nOn what name should we make the appointment for?"
    read CUSTOMER_NAME

    NEW_CUSTOMER=$($PSQL "INSERT INTO customers(phone, name) VALUES('$CUSTOMER_PHONE', '$CUSTOMER_NAME')")
    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")
  fi
  
  CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")

  # Get appointment time
  echo -e "\nWhat time would you like your appointment, $CUSTOMER_NAME?"
  read SERVICE_TIME

  # Insert the new appointment
  NEW_APPOINTMENT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")

  # Check if the insert was successful
  if [[ $? == 0 ]]
  then
    SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")
    echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
  else
    echo -e "\nSomething went wrong, please try again later."
  fi
}

EXIT() {
  echo -e "\nHave a wonderful day!"
}

MAIN_MENU