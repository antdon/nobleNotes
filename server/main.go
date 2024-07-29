package main

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"
)

type note struct {
	ID           string `json:"id"`
	Title        string `json:"title"`
	Content      string `json:"content"`
	CreationDate string `json:"creationdate"`
}

var notes = []note{
	{ID: "1", Title: "boat 1", Content: "Boat 1 content", CreationDate: "20/05/24"},
	{ID: "2", Title: "note 2", Content: "Note 2 content", CreationDate: "20/05/24"},
	{ID: "3", Title: "note 3", Content: "Note 3 content", CreationDate: "20/05/24"},
	{ID: "4", Title: "note 4", Content: "Note 4 content", CreationDate: "20/05/24"},
}

func getNotes(c *gin.Context) {
	c.IndentedJSON(http.StatusOK, notes)
}

func createNote(c *gin.Context) {
	var newNote note

	if err := c.BindJSON(&newNote); err != nil {
		return
	}

	notes = append(notes, newNote)
	c.IndentedJSON(http.StatusCreated, newNote)
}

func deleteNote(c *gin.Context) {
	id, ok := c.GetQuery("id")

	if !ok {
		c.IndentedJSON(http.StatusBadRequest, gin.H{"message": "Please specify ID of note you would like to delete"})
		return
	}

	err := deleteNoteById(id)
	if err != nil {
		c.IndentedJSON(http.StatusBadRequest, gin.H{"message": err.Error()})
	}
}

func updateNote(c *gin.Context) {
	id, ok := c.GetQuery("id")
	if !ok {
		c.IndentedJSON(http.StatusBadRequest, gin.H{"message": "Please specify ID of note you would like to update"})
		return
	}
	title, ok := c.GetQuery("title")
	if !ok {
		c.IndentedJSON(http.StatusBadRequest, gin.H{"message": "Please specify the updated title"})
		return
	}
	content, ok := c.GetQuery("content")
	if !ok {
		c.IndentedJSON(http.StatusBadRequest, gin.H{"message": "Please specify the updated content"})
		return
	}

	for i := 0; i < len(notes); i++ {
		if notes[i].ID == id {
			notes[i].Title = title
			notes[i].Content = content
		}
	}

}

func getFirstNote(c *gin.Context) {
	c.IndentedJSON(http.StatusOK, notes[0])
}

func getNoteIndexById(id string) (int, error) {
	for i, n := range notes {
		if n.ID == id {
			return i, nil
		}
	}
	return -1, errors.New("note not found")
}

func deleteNoteById(id string) error {
	index, err := getNoteIndexById(id)
	if err != nil {
		return err
	}
	notes = append(notes[:index], notes[index+1:]...)
	return nil
}

func main() {
	router := gin.Default()
	router.GET("/notes", getNotes)
	router.GET("/note", getFirstNote)
	router.PATCH("/notes/delete", deleteNote)
	router.POST("/notes/create", createNote)
	router.PATCH("/notes/update", updateNote)
	router.Run("0.0.0.0:8080")
}
