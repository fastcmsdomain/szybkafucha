Flow 

we need to change the flow
1. Client Tab Button “dodaj zlecenie”
job created: client screen
 Job status: created
clients create the job by adding:
1. Job category (Category)
2. Job description (opis)
3. Zdjecie upload (fully integrated with the contractor dashboard)
4. Job location (wpisz address)
5. Job budget (35zl minimum, nie ustawiamy maksymalnej stawke)
6. Job date (Użyj mojej lokalizacji, termin)
7. Below the update summary (podsumowanie)
8. button ‘znajdź pomocnika’
Job status: created
contractor: Szukanie

->

2.Contractor tap button ‘przyjmij’
szczegoly zlecenia - contractor screen
Job status: created
Contractor see the job and viewing it
1. Category icon and category name with the date of creation.
2. Next to it, the price (in zł)
3. Description – Opis Zlecenia
4. Location – Lokalizacja z mapą i buttonem nawiguj z adresem wpisanym przez klienta
5. Client Card: Image, Name, Rating, and Bottom Profile (anchor to client profil pop up with all important client information, rating and feeback)
6. Button:  przyjmij zlecenie
Contractor can confirm the job by taping ‘przyjmij zlecenie’ 
status ‘accepted’
contractor: Oczekuje  ->  Client : Znaleziony

->
Screen Active Job for client
Job status ‘accepted’
Client screen see the job been accepted and must confirm the contractor
3.1.The client receives an update on his job: ‘pomocnik znaleziony’. The active job opens for a client.
Client screen includes from top:
1. map (center on the mark), back button, reload button, tools button (szczegoly zlecenia, Zgłoś problem, Anuluj zlecenie)
2. Pomocnik znaleziony - title, Sprawdź profil i zweryfikuj wykonawcę - subtitle
3. progress card dots different rainbow colours witch check icons when completed)
4. Task card: icon and name, location, description and price, 
5. Contractor profile card: photo , name, rating, contractor profile button (anchor to profile pop up includes all detail information), chat button and phone button (same as the contractor screen)
6. Buttons: Zatwierdź (accept the contractor and pay), Odrzuć i szukaj innego (cancel the contractor), anuluj zlecenie (cancel the job)

once client confirm the contractor so add "Zatwiedz" button that will toggle pop up with payment (client need to pay to admin (add two buttons cash and card (side by side) as placeholders for future implementation) add “zatwiedz” below the payment buttons . Client tap ‘Zatwierdz’ status change to ‘potiwrdz’ 


Screen Active job for contractor
3.2 Contractor sees the job Accepted, but waiting for the confirmation from the client.
1. Contractor screen  (active job)- Aktywne zlecenie includes:
    1. Map with the location mark and the button 'Nawiguj'
    2. progress card dots (these must be smaller, same size as the client dots. These dost must be different rainbow colours witch check icons when completed)
    3. Task card: icon and  name, location, description and price, 
    4. client profile card: photo , name, rating, client profile button (photo, name , rating with few feedbacks with button ’caly profil’ button placeholder)
    5. Info “Klient musi potwierdzić przyjęcie zlecenia. Poczekaj na potwierdzenie.”Buttons: “Oczekuję na potwierdzenie” and “Anuluj” 
Remove the step ‘Do potwierdzenia’ 
Status confirmed
Client tap “Zatwierdz”
contractor: potwiedzony -> Client : potwiedzony
Then the contractor receives a status update ‘potwierdz’ and can start the job status changes to ‘w trakcie’ (inProgress)

-> 
4. Contractor started the job statu: in_progress
contractor: w trakcie -> Client : w trakcie


Active job FLOW
1. The contractor can now start the job by tapping the button 'Rozpocznij'.
2. Once the contractor starts the job, the status will update to In progress, and on the screen of contractor status changes ‘W trakcie.’ 
3. Same for the client, the status will become 'W trakcie'.
4. Client and Contractor now communicate with each other by chat.
5. Once the contractor finishes the job, the client has to confirm it first. 
6. The contractor button ‘Zakończ zlecenie’ is disabled. 
7. Only the client can confirm the job complete or the job cancellation.
8. Once the job is completed, the client has to tap ‘Zlecenie zakonczone’. The client will be redirected to a screen ‘Zlecenie zakończone.’ With current layout that includes: star rating (required), zostaw opinie (optional) and napiwek (optional), który już istniej, button ‘Wyslij opinie’ JJOB STATUS: complated_panding
9. At the same time, the contractor receives a message on his account with status “ zakoncone” Once the job is complete it the contractor will be redirected to a similar screen for the rating and opinion.JOB STATUS: complated_panding
10. The job will be considered completed once the contractor and the client finish the job by tapping the Complete button. The status will then be updated to completed on both sides. The status: complet_rating must be approved from both sides to consider the job completed.
11. contractor then receives message (client confirm) contractor get pay.
12. Create an endpoint for the money received by the contractor that can be then added to his personal account.
13. Create and link the rating to the contractor and client profile. If the content feedback text is added by the client or contractor, it must also be included in the profile of that client or contractor.
14. Kiedy klient potwierdzi lub zmieni status jakiejkolwiek pracy, powinna być ona aktualizowana bezpośrednio i od razu, bez konieczności odświeżania ekranu przez kontraktora.
15. Kiedy kontraktor zmieni status obiegu pracy, powinien zostać on zaktualizowany bezpośrednio i od razu, bez konieczności odświeżania strony przez klienta.


1. I need to create one new status
2. Make sure the backend is integrated with the flow.
3. If anything is uncertain or unclear, ask me.
4. Create the documentation for the flow and update the task for PRD.
5. Use the furrent UX and UI but enhance this using /frontend-design skill
6. test everthing before completetion
7. perform unit testing and smode test
8. create a guide to test the flw by QA and me
9. make sure this need to be comatible and work with thr Cancelation flow of the job 
