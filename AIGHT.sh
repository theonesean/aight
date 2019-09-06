#!/bin/bash

# AIGHT, v0.2

board=5d57c32e1538894e6c0b66ca
todolist=5d5d204dd12e9b7c9d659351
doinglist=5d5d212481dcf4310fe29dfd


if [[ $PWD == *trevian* ]];
then
    # get tasks from trello
    todocards=$(curl -s -S "https://api.trello.com/1/list/$todolist/cards?fields=name,labels&key=$TRELLO_KEY&token=$TRELLO_TOKEN")
    doingcards=$(curl -s -S "https://api.trello.com/1/list/$doinglist/cards?fields=name,labels&key=$TRELLO_KEY&token=$TRELLO_TOKEN")
    echo "trevian tasks"
    echo "----------------"
    echo ""
    echo "TODO"
    echo $todocards | jq .[].name  
    echo ""
    echo "DOING"
    echo $doingcards | jq .[].name
else
    open things:///show?id=today
fi
    
